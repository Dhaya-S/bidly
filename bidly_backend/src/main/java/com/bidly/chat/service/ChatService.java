package com.bidly.chat.service;

import com.bidly.chat.dto.*;
import com.bidly.chat.entity.ChatMessage;
import com.bidly.chat.entity.ChatRoom;
import com.bidly.chat.repository.ChatMessageRepository;
import com.bidly.chat.repository.ChatRoomRepository;
import com.bidly.common.exception.BidlyException;
import com.bidly.listing.entity.Listing;
import com.bidly.listing.repository.ListingRepository;
import com.bidly.media.service.MediaService;
import com.bidly.user.entity.User;
import com.bidly.user.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.PageRequest;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.time.Duration;
import java.time.Instant;
import java.util.*;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
public class ChatService {

    private static final Logger log = LoggerFactory.getLogger(ChatService.class);

    private final ChatRoomRepository roomRepo;
    private final ChatMessageRepository messageRepo;
    private final ListingRepository listingRepo;
    private final UserRepository userRepo;
    private final com.bidly.offer.repository.OfferRepository offerRepo;
    private final MediaService mediaService;
    private final SimpMessagingTemplate messagingTemplate;

    public ChatService(ChatRoomRepository roomRepo,
                       ChatMessageRepository messageRepo,
                       ListingRepository listingRepo,
                       UserRepository userRepo,
                       com.bidly.offer.repository.OfferRepository offerRepo,
                       MediaService mediaService,
                       SimpMessagingTemplate messagingTemplate) {
        this.roomRepo          = roomRepo;
        this.messageRepo       = messageRepo;
        this.listingRepo       = listingRepo;
        this.userRepo          = userRepo;
        this.offerRepo         = offerRepo;
        this.mediaService      = mediaService;
        this.messagingTemplate = messagingTemplate;
    }

    @Transactional
    public ChatRoomDto getOrCreateRoom(UUID listingId, UUID currentUserId, UUID targetBuyerId, UUID offerId) {
        if (currentUserId == null) {
            throw BidlyException.unauthorized("Authentication required to use chat");
        }
        Listing listing = listingRepo.findById(listingId)
                .orElseThrow(() -> BidlyException.notFound("Listing not found: " + listingId));

        User seller = listing.getSeller();
        if (seller == null) {
            throw BidlyException.badRequest("Listing does not have a valid seller");
        }
        UUID sellerId = seller.getId();
        UUID buyerId;

        if (currentUserId.equals(sellerId)) {
            // Current requester is the SELLER
            if (targetBuyerId != null) {
                buyerId = targetBuyerId;
            } else if (offerId != null) {
                com.bidly.offer.entity.Offer offer = offerRepo.findById(offerId)
                        .orElseThrow(() -> BidlyException.notFound("Offer not found: " + offerId));
                buyerId = offer.getBuyer().getId();
            } else {
                List<ChatRoom> rooms = roomRepo.findByListingId(listingId);
                if (rooms.size() == 1) {
                    buyerId = rooms.get(0).getBuyerId();
                } else if (rooms.isEmpty()) {
                    List<com.bidly.offer.entity.Offer> offers = offerRepo.findByListingIdOrderByCreatedAtDesc(listingId);
                    if (offers.size() == 1) {
                        buyerId = offers.get(0).getBuyer().getId();
                    } else if (offers.isEmpty()) {
                        throw BidlyException.badRequest("No offers or active conversations for this listing");
                    } else {
                        throw BidlyException.badRequest("Multiple offers exist. Please specify buyerId or offerId to open the correct chat.");
                    }
                } else {
                    throw BidlyException.badRequest("Multiple conversations exist. Please specify buyerId or offerId to open the correct chat.");
                }
            }
        } else {
            // Current requester is the BUYER
            buyerId = currentUserId;
        }

        if (buyerId.equals(sellerId)) {
            throw BidlyException.badRequest("Buyer and seller cannot be the same user");
        }

        final UUID finalBuyerId = buyerId;
        return roomRepo.findByListingIdAndBuyerId(listingId, finalBuyerId)
                .map(r -> mapRoomToDto(r, currentUserId))
                .orElseGet(() -> {
                    ChatRoom room = new ChatRoom();
                    room.setListingId(listingId);
                    room.setBuyerId(finalBuyerId);
                    room.setSellerId(sellerId);
                    ChatRoom saved = roomRepo.save(room);
                    log.info("[CHAT] Created new chat room {} for listing {} between buyer {} and seller {}",
                            saved.getId(), listingId, finalBuyerId, sellerId);
                    return mapRoomToDto(saved, currentUserId);
                });
    }

    @Transactional
    public ChatRoomDto getOrCreateRoom(UUID listingId, UUID buyerId) {
        return getOrCreateRoom(listingId, buyerId, null, null);
    }

    /** List all chat rooms where user is buyer or seller with unread counts using batch queries. */
    @Transactional(readOnly = true)
    public List<ChatRoomDto> listRooms(UUID userId) {
        if (userId == null) {
            throw BidlyException.unauthorized("Authentication required");
        }
        List<ChatRoom> rooms = roomRepo.findAllByUserId(userId);
        if (rooms.isEmpty()) {
            return Collections.emptyList();
        }

        List<UUID> roomIds = rooms.stream().map(ChatRoom::getId).collect(Collectors.toList());

        // Batch fetch all associated listings in 1 query
        Set<UUID> listingIds = rooms.stream().map(ChatRoom::getListingId).filter(Objects::nonNull).collect(Collectors.toSet());
        Map<UUID, Listing> listingMap = listingRepo.findAllById(listingIds).stream()
                .collect(Collectors.toMap(Listing::getId, Function.identity(), (a, b) -> a));

        // Batch fetch all buyers and sellers in 1 query
        Set<UUID> userIds = new HashSet<>();
        for (ChatRoom r : rooms) {
            if (r.getBuyerId() != null) userIds.add(r.getBuyerId());
            if (r.getSellerId() != null) userIds.add(r.getSellerId());
        }
        Map<UUID, User> userMap = userRepo.findAllById(userIds).stream()
                .collect(Collectors.toMap(User::getId, Function.identity(), (a, b) -> a));

        // Batch fetch unread counts in 1 query
        Map<UUID, Integer> unreadMap = new HashMap<>();
        List<Object[]> unreadCounts = messageRepo.countUnreadInRooms(roomIds, userId);
        for (Object[] row : unreadCounts) {
            if (row != null && row.length >= 2 && row[0] instanceof UUID && row[1] instanceof Number) {
                unreadMap.put((UUID) row[0], ((Number) row[1]).intValue());
            }
        }

        // Batch fetch latest message for each room in 1 query
        Map<UUID, ChatMessage> latestMessageMap = new HashMap<>();
        List<ChatMessage> recentMessages = messageRepo.findRecentMessagesInRooms(roomIds);
        for (ChatMessage m : recentMessages) {
            latestMessageMap.putIfAbsent(m.getRoomId(), m);
        }

        return rooms.stream()
                .map(r -> mapRoomToDto(r, userId, listingMap, userMap, unreadMap, latestMessageMap))
                .collect(Collectors.toList());
    }

    /** Get deterministic messages with keyset pagination support. */
    @Transactional(readOnly = true)
    public List<ChatMessageDto> getMessages(UUID roomId, UUID currentUserId, Instant beforeCreatedAt, UUID beforeId, Integer limit) {
        validateAccess(roomId, currentUserId);
        int pageSize = (limit != null && limit > 0 && limit <= 100) ? limit : 50;

        List<ChatMessage> msgs;
        if (beforeCreatedAt != null && beforeId != null) {
            msgs = messageRepo.findOlderMessages(roomId, beforeCreatedAt, beforeId, PageRequest.of(0, pageSize));
            // Reverse so they are returned in ascending order
            Collections.reverse(msgs);
        } else {
            msgs = messageRepo.findByRoomIdOrderByCreatedAtAscIdAsc(roomId);
            if (msgs.size() > pageSize) {
                msgs = msgs.subList(msgs.size() - pageSize, msgs.size());
            }
        }

        return msgs.stream().map(m -> mapMsgToDto(m, currentUserId)).collect(Collectors.toList());
    }

    /**
     * Send a message with clientMessageId idempotency and post-commit WebSocket broadcast.
     */
    @Transactional
    public ChatMessageDto sendMessage(UUID roomId, UUID senderId, SendMessageRequest req) {
        validateAccess(roomId, senderId);
        ChatRoom room = roomRepo.findById(roomId)
                .orElseThrow(() -> BidlyException.notFound("Chat room not found"));

        // Idempotency check: if clientMessageId already exists in this room, return existing
        if (req.getClientMessageId() != null && !req.getClientMessageId().trim().isEmpty()) {
            Optional<ChatMessage> existing = messageRepo.findByRoomIdAndClientMessageId(roomId, req.getClientMessageId().trim());
            if (existing.isPresent()) {
                log.info("[CHAT_IDEMPOTENT] Returning existing message {} for clientMessageId {}",
                        existing.get().getId(), req.getClientMessageId());
                return mapMsgToDto(existing.get(), senderId);
            }
        }

        ChatMessage msg = new ChatMessage();
        msg.setRoomId(roomId);
        msg.setSenderId(senderId);
        msg.setClientMessageId(req.getClientMessageId() != null ? req.getClientMessageId().trim() : null);
        msg.setContent(req.getContent());
        msg.setOfferAmount(req.getOfferAmount());
        msg.setMediaUrl(req.getMediaUrl());
        msg.setMetadata(req.getMetadata());
        msg.setStatus(ChatMessage.MessageStatus.SENT);

        try {
            msg.setType(ChatMessage.MessageType.valueOf(
                    req.getType() != null ? req.getType().toUpperCase() : "TEXT"));
        } catch (IllegalArgumentException e) {
            msg.setType(ChatMessage.MessageType.TEXT);
        }

        ChatMessage saved = messageRepo.save(msg);
        room.setLastMessageAt(saved.getCreatedAt());
        room.setUpdatedAt(Instant.now());
        roomRepo.save(room);

        ChatMessageDto dto = mapMsgToDto(saved, senderId);
        UUID receiverId = room.getBuyerId().equals(senderId) ? room.getSellerId() : room.getBuyerId();

        // Broadcast to STOMP topic after database commit
        if (TransactionSynchronizationManager.isSynchronizationActive()) {
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override
                public void afterCommit() {
                    broadcastMessageEvent(roomId, receiverId, dto);
                }
            });
        } else {
            broadcastMessageEvent(roomId, receiverId, dto);
        }

        return dto;
    }

    private void broadcastMessageEvent(UUID roomId, UUID receiverId, ChatMessageDto dto) {
        try {
            ChatEventDto event = ChatEventDto.newMessage(roomId, dto);
            messagingTemplate.convertAndSend("/topic/chats/" + roomId, event);
            messagingTemplate.convertAndSend("/topic/users/" + receiverId + "/chat", event);
            log.info("[CHAT_WS] BROADCAST message roomId={} msgId={} sender={}", roomId, dto.getId(), dto.getSenderId());
        } catch (Exception e) {
            log.warn("[CHAT_WS] Failed to broadcast message: {}", e.getMessage());
        }
    }

    /**
     * Mark all unread messages in room as READ and broadcast read receipts.
     */
    @Transactional
    public void markRoomMessagesAsRead(UUID roomId, UUID readerId) {
        validateAccess(roomId, readerId);
        List<ChatMessage> unread = messageRepo.findUnreadMessagesInRoom(roomId, readerId);
        if (unread.isEmpty()) {
            return;
        }

        Instant now = Instant.now();
        List<UUID> readIds = new ArrayList<>();
        for (ChatMessage m : unread) {
            m.setStatus(ChatMessage.MessageStatus.READ);
            m.setReadAt(now);
            readIds.add(m.getId());
        }
        messageRepo.saveAll(unread);

        if (TransactionSynchronizationManager.isSynchronizationActive()) {
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override
                public void afterCommit() {
                    try {
                        ChatEventDto event = ChatEventDto.messageRead(roomId, readerId, now, readIds);
                        messagingTemplate.convertAndSend("/topic/chats/" + roomId, event);
                        log.info("[CHAT_WS] BROADCAST read receipt roomId={} count={}", roomId, readIds.size());
                    } catch (Exception e) {
                        log.warn("[CHAT_WS] Failed to broadcast read receipt: {}", e.getMessage());
                    }
                }
            });
        }
    }

    /**
     * Send ephemeral typing indicator to WebSocket topic without storing in DB.
     */
    public void sendTypingIndicator(UUID roomId, UUID userId, boolean isTyping) {
        validateAccess(roomId, userId);
        String userName = userRepo.findById(userId).map(User::getName).orElse("User");
        ChatEventDto event = isTyping
                ? ChatEventDto.typingStarted(roomId, userId, userName)
                : ChatEventDto.typingStopped(roomId, userId);

        messagingTemplate.convertAndSend("/topic/chats/" + roomId, event);
        log.debug("[CHAT_WS] Ephemeral typing event: {} user: {} room: {}", event.getEventType(), userId, roomId);
    }

    // --- Helpers ---

    private void validateAccess(UUID roomId, UUID userId) {
        ChatRoom room = roomRepo.findById(roomId)
                .orElseThrow(() -> BidlyException.notFound("Chat room not found: " + roomId));
        if (!room.getBuyerId().equals(userId) && !room.getSellerId().equals(userId)) {
            throw BidlyException.forbidden("Access denied to this chat room");
        }
    }

    private ChatRoomDto mapRoomToDto(ChatRoom r, UUID currentUserId) {
        ChatRoomDto dto = new ChatRoomDto();
        dto.setId(r.getId());
        dto.setListingId(r.getListingId());
        dto.setBuyerId(r.getBuyerId());
        dto.setSellerId(r.getSellerId());
        dto.setStatus(r.getStatus().name());
        dto.setLastMessageAt(r.getLastMessageAt());
        dto.setCreatedAt(r.getCreatedAt());

        listingRepo.findById(r.getListingId()).ifPresent(l -> {
            dto.setListingTitle(l.getTitle());
            dto.setListingPrice(l.getPrice() != null ? l.getPrice().doubleValue() : 0.0);
            if (l.getMedia() != null && !l.getMedia().isEmpty()) {
                String presigned = mediaService.generatePresignedGetUrl(l.getMedia().get(0).getUrl(), Duration.ofHours(4));
                dto.setListingImageUrl(presigned != null ? presigned : l.getMedia().get(0).getUrl());
            }
        });

        userRepo.findById(r.getBuyerId()).ifPresent(u -> dto.setBuyerName(u.getName()));
        userRepo.findById(r.getSellerId()).ifPresent(u -> dto.setSellerName(u.getName()));

        boolean isBuyer = currentUserId.equals(r.getBuyerId());
        UUID otherId = isBuyer ? r.getSellerId() : r.getBuyerId();
        String otherName = isBuyer ? dto.getSellerName() : dto.getBuyerName();
        dto.setOtherUserId(otherId);
        dto.setOtherUserName(otherName != null ? otherName : (isBuyer ? "Seller" : "Buyer"));
        dto.setOtherUserRole(isBuyer ? "Seller" : "Buyer");

        long unread = messageRepo.countUnreadInRoom(r.getId(), currentUserId);
        dto.setUnreadCount((int) unread);

        messageRepo.findTopByRoomIdOrderByCreatedAtDesc(r.getId()).ifPresent(m -> {
            if (m.getType() == ChatMessage.MessageType.OFFER && m.getOfferAmount() != null) {
                dto.setLastMessagePreview("Offer: ₹" + m.getOfferAmount().toBigInteger());
            } else if (m.getType() == ChatMessage.MessageType.MEETUP_REQUEST) {
                dto.setLastMessagePreview("📅 In-Person Meetup Request");
            } else if (m.getType() == ChatMessage.MessageType.IMAGE) {
                dto.setLastMessagePreview("📷 Photo attachment");
            } else if (m.getContent() != null) {
                dto.setLastMessagePreview(m.getContent());
            }
        });
        return dto;
    }

    private ChatRoomDto mapRoomToDto(ChatRoom r, UUID currentUserId,
                                    Map<UUID, Listing> listingMap,
                                    Map<UUID, User> userMap,
                                    Map<UUID, Integer> unreadMap,
                                    Map<UUID, ChatMessage> latestMessageMap) {
        ChatRoomDto dto = new ChatRoomDto();
        dto.setId(r.getId());
        dto.setListingId(r.getListingId());
        dto.setBuyerId(r.getBuyerId());
        dto.setSellerId(r.getSellerId());
        dto.setStatus(r.getStatus().name());
        dto.setLastMessageAt(r.getLastMessageAt());
        dto.setCreatedAt(r.getCreatedAt());

        Listing l = listingMap.get(r.getListingId());
        if (l != null) {
            dto.setListingTitle(l.getTitle());
            dto.setListingPrice(l.getPrice() != null ? l.getPrice().doubleValue() : 0.0);
            if (l.getMedia() != null && !l.getMedia().isEmpty()) {
                String presigned = mediaService.generatePresignedGetUrl(l.getMedia().get(0).getUrl(), Duration.ofHours(4));
                dto.setListingImageUrl(presigned != null ? presigned : l.getMedia().get(0).getUrl());
            }
        }

        User buyer = userMap.get(r.getBuyerId());
        if (buyer != null) dto.setBuyerName(buyer.getName());

        User seller = userMap.get(r.getSellerId());
        if (seller != null) dto.setSellerName(seller.getName());

        boolean isBuyer = currentUserId.equals(r.getBuyerId());
        UUID otherId = isBuyer ? r.getSellerId() : r.getBuyerId();
        String otherName = isBuyer ? dto.getSellerName() : dto.getBuyerName();
        dto.setOtherUserId(otherId);
        dto.setOtherUserName(otherName != null ? otherName : (isBuyer ? "Seller" : "Buyer"));
        dto.setOtherUserRole(isBuyer ? "Seller" : "Buyer");

        dto.setUnreadCount(unreadMap.getOrDefault(r.getId(), 0));

        ChatMessage m = latestMessageMap.get(r.getId());
        if (m != null) {
            if (m.getType() == ChatMessage.MessageType.OFFER && m.getOfferAmount() != null) {
                dto.setLastMessagePreview("Offer: ₹" + m.getOfferAmount().toBigInteger());
            } else if (m.getType() == ChatMessage.MessageType.MEETUP_REQUEST) {
                dto.setLastMessagePreview("📅 In-Person Meetup Request");
            } else if (m.getType() == ChatMessage.MessageType.IMAGE) {
                dto.setLastMessagePreview("📷 Photo attachment");
            } else if (m.getContent() != null) {
                dto.setLastMessagePreview(m.getContent());
            }
        }
        return dto;
    }

    private ChatMessageDto mapMsgToDto(ChatMessage m, UUID currentUserId) {
        ChatMessageDto dto = new ChatMessageDto();
        dto.setId(m.getId());
        dto.setRoomId(m.getRoomId());
        dto.setSenderId(m.getSenderId());
        dto.setClientMessageId(m.getClientMessageId());
        dto.setContent(m.getContent());
        dto.setOfferAmount(m.getOfferAmount());
        dto.setType(m.getType().name());
        dto.setStatus(m.getStatus().name());
        dto.setReadAt(m.getReadAt());
        if (m.getType() == ChatMessage.MessageType.IMAGE && m.getMediaUrl() != null && !m.getMediaUrl().isBlank()) {
            String presigned = mediaService.generatePresignedGetUrl(m.getMediaUrl(), Duration.ofHours(24));
            dto.setMediaUrl(presigned != null ? presigned : m.getMediaUrl());
        } else {
            dto.setMediaUrl(m.getMediaUrl());
        }
        dto.setMetadata(m.getMetadata());
        dto.setMine(currentUserId != null && m.getSenderId().equals(currentUserId));
        dto.setCreatedAt(m.getCreatedAt());

        userRepo.findById(m.getSenderId()).ifPresent(u -> dto.setSenderName(u.getName()));
        return dto;
    }
}
