package com.bidly.offer.service;

import com.bidly.chat.dto.ChatEventDto;
import com.bidly.chat.dto.ChatMessageDto;
import com.bidly.chat.entity.ChatMessage;
import com.bidly.chat.entity.ChatRoom;
import com.bidly.chat.repository.ChatMessageRepository;
import com.bidly.chat.repository.ChatRoomRepository;
import com.bidly.common.exception.BidlyException;
import com.bidly.listing.entity.Listing;
import com.bidly.listing.repository.ListingRepository;
import com.bidly.media.service.MediaService;
import com.bidly.offer.dto.*;
import com.bidly.offer.entity.Offer;
import com.bidly.offer.repository.OfferRepository;
import com.bidly.order.entity.Order;
import com.bidly.order.service.OrderService;
import com.bidly.user.entity.User;
import com.bidly.user.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
public class OfferService {

    private static final Logger log = LoggerFactory.getLogger(OfferService.class);

    private final OfferRepository offerRepository;
    private final ListingRepository listingRepository;
    private final UserRepository userRepository;
    private final OrderService orderService;
    private final com.bidly.order.repository.OrderRepository orderRepository;
    private final ChatRoomRepository chatRoomRepository;
    private final ChatMessageRepository chatMessageRepository;
    private final MediaService mediaService;
    private final SimpMessagingTemplate messagingTemplate;
    private final com.bidly.notification.service.NotificationService notificationService;

    public OfferService(
            OfferRepository offerRepository,
            ListingRepository listingRepository,
            UserRepository userRepository,
            OrderService orderService,
            com.bidly.order.repository.OrderRepository orderRepository,
            ChatRoomRepository chatRoomRepository,
            ChatMessageRepository chatMessageRepository,
            MediaService mediaService,
            SimpMessagingTemplate messagingTemplate,
            com.bidly.notification.service.NotificationService notificationService) {
        this.offerRepository = offerRepository;
        this.listingRepository = listingRepository;
        this.userRepository = userRepository;
        this.orderService = orderService;
        this.orderRepository = orderRepository;
        this.chatRoomRepository = chatRoomRepository;
        this.chatMessageRepository = chatMessageRepository;
        this.mediaService = mediaService;
        this.messagingTemplate = messagingTemplate;
        this.notificationService = notificationService;
    }

    /**
     * Buyer creates a new Offer on a Direct Sale listing.
     */
    @Transactional
    public OfferDto createOffer(UUID listingId, UUID buyerId, CreateOfferRequest req) {
        if (buyerId == null) {
            throw BidlyException.unauthorized("Authentication required to make an offer");
        }
        if (req.getAmount() == null || req.getAmount().signum() <= 0) {
            throw BidlyException.badRequest("Valid offer amount is required");
        }

        Listing listing = listingRepository.findById(listingId)
                .orElseThrow(() -> BidlyException.notFound("Listing not found: " + listingId));

        if (listing.getSellingMethod() != Listing.SellingMethod.DIRECT_BUY) {
            throw BidlyException.badRequest("This listing is an Auction and does not accept direct sale offers");
        }

        if (listing.getStatus() != Listing.ListingStatus.ACTIVE) {
            throw BidlyException.badRequest("This listing is no longer active (Status: " + listing.getStatus() + ")");
        }

        User buyer = userRepository.findById(buyerId)
                .orElseThrow(() -> BidlyException.notFound("Buyer user not found"));

        User seller = listing.getSeller();
        if (seller != null && seller.getId().equals(buyerId)) {
            throw BidlyException.badRequest("You cannot make an offer on your own listing");
        }

        if (req.getClientOfferId() != null && !req.getClientOfferId().isBlank()) {
            Optional<Offer> existing = offerRepository.findByClientOfferId(req.getClientOfferId().trim());
            if (existing.isPresent()) {
                log.info("[IDEMPOTENCY] Found existing offer with clientOfferId {}", req.getClientOfferId());
                return mapToDto(existing.get(), buyerId);
            }
        }

        Offer offer = new Offer(listing, buyer, seller, req.getAmount(), req.getMessage());
        offer.setExpiresAt(Instant.now().plus(Duration.ofDays(3)));
        if (req.getClientOfferId() != null && !req.getClientOfferId().isBlank()) {
            offer.setClientOfferId(req.getClientOfferId().trim());
        }
        Offer saved = offerRepository.save(offer);

        // Ensure chat room exists and post offer message
        ChatRoom room = chatRoomRepository.findByListingIdAndBuyerId(listingId, buyerId)
                .orElseGet(() -> {
                    ChatRoom r = new ChatRoom();
                    r.setListingId(listingId);
                    r.setBuyerId(buyerId);
                    r.setSellerId(seller.getId());
                    return chatRoomRepository.save(r);
                });

        ChatMessage msg = new ChatMessage();
        msg.setRoomId(room.getId());
        msg.setSenderId(buyerId);
        msg.setType(ChatMessage.MessageType.OFFER);
        msg.setOfferAmount(req.getAmount());
        msg.setStatus(ChatMessage.MessageStatus.SENT);
        msg.setContent(req.getMessage() != null && !req.getMessage().isBlank()
                ? req.getMessage().trim()
                : "Submitted an offer of ₹" + req.getAmount().toBigInteger());
        ChatMessage savedMsg = chatMessageRepository.save(msg);
        room.setLastMessageAt(Instant.now());
        room.setUpdatedAt(Instant.now());
        chatRoomRepository.save(room);

        // Broadcast to WebSocket after commit
        broadcastOfferEvent(room.getId(), saved.getId(), "PENDING", req.getAmount().doubleValue(), null, savedMsg, buyer.getName());

        // Send persistent notification & real-time alert to Seller
        if (seller != null) {
            String metadataJson = String.format(
                    "{\"offerAmount\":%s,\"listingPrice\":%s,\"buyerName\":\"%s\",\"buyerId\":\"%s\",\"offerId\":\"%s\"}",
                    saved.getAmount(), listing.getPrice(), buyer.getName(), buyer.getId(), saved.getId());

            notificationService.sendNotification(
                    seller,
                    com.bidly.notification.entity.Notification.NotificationType.NEW_OFFER,
                    "New Offer Received",
                    buyer.getName() + " made an offer on " + listing.getTitle(),
                    listing,
                    saved,
                    null,
                    "View Offer",
                    "/chat/offer/" + listingId,
                    saved.getId(),
                    metadataJson
            );
        }

        log.info("Offer of Rs. {} submitted for listing '{}' by buyer '{}'", req.getAmount(), listing.getTitle(), buyer.getName());
        return mapToDto(saved, buyerId);
    }

    /**
     * Seller or Buyer submits a counter-offer.
     */
    @Transactional
    public OfferDto counterOffer(UUID offerId, UUID currentUserId, CounterOfferRequest req) {
        if (currentUserId == null) {
            throw BidlyException.unauthorized("Authentication required");
        }
        if (req.getCounterAmount() == null || req.getCounterAmount().signum() <= 0) {
            throw BidlyException.badRequest("Valid counter offer amount is required");
        }

        Offer offer = offerRepository.findByIdWithPessimisticLock(offerId)
                .orElseThrow(() -> BidlyException.notFound("Offer not found: " + offerId));

        if (offer.getStatus() != Offer.OfferStatus.PENDING && offer.getStatus() != Offer.OfferStatus.COUNTERED) {
            throw BidlyException.badRequest("Cannot counter an offer that is " + offer.getStatus());
        }

        boolean isSeller = currentUserId.equals(offer.getSeller().getId());
        boolean isBuyer = currentUserId.equals(offer.getBuyer().getId());
        if (!isSeller && !isBuyer) {
            throw BidlyException.forbidden("You are not authorized to negotiate this offer");
        }

        offer.setCounterAmount(req.getCounterAmount());
        offer.setStatus(Offer.OfferStatus.COUNTERED);
        offer.setMessage(req.getMessage());
        Offer saved = offerRepository.save(offer);

        // Post counter message to chat room
        ChatRoom room = chatRoomRepository.findByListingIdAndBuyerId(offer.getListing().getId(), offer.getBuyer().getId()).orElse(null);
        if (room != null) {
            ChatMessage msg = new ChatMessage();
            msg.setRoomId(room.getId());
            msg.setSenderId(currentUserId);
            msg.setType(ChatMessage.MessageType.OFFER_COUNTERED);
            msg.setOfferAmount(req.getCounterAmount());
            msg.setStatus(ChatMessage.MessageStatus.SENT);
            msg.setContent("Counter offer of ₹" + req.getCounterAmount().toBigInteger() + (req.getMessage() != null ? ": " + req.getMessage() : ""));
            ChatMessage savedMsg = chatMessageRepository.save(msg);
            room.setLastMessageAt(Instant.now());
            room.setUpdatedAt(Instant.now());
            chatRoomRepository.save(room);

            String senderName = userRepository.findById(currentUserId).map(User::getName).orElse("User");
            broadcastOfferEvent(room.getId(), saved.getId(), "COUNTERED", offer.getAmount().doubleValue(), req.getCounterAmount().doubleValue(), savedMsg, senderName);
        }

        // Send persistent notification & real-time alert for Counter Offer
        User recipient = isSeller ? offer.getBuyer() : offer.getSeller();
        String counterSender = userRepository.findById(currentUserId).map(User::getName).orElse("User");
        String counterMeta = String.format(
                "{\"counterAmount\":%s,\"listingPrice\":%s,\"buyerName\":\"%s\",\"buyerId\":\"%s\",\"offerId\":\"%s\"}",
                req.getCounterAmount(), offer.getListing().getPrice(), offer.getBuyer().getName(), offer.getBuyer().getId(), saved.getId());

        notificationService.sendNotification(
                recipient,
                com.bidly.notification.entity.Notification.NotificationType.NEW_OFFER,
                "Counter Offer Received",
                counterSender + " sent a counter offer of ₹" + req.getCounterAmount().toBigInteger() + " on " + offer.getListing().getTitle(),
                offer.getListing(),
                saved,
                null,
                "View Offer",
                "/chat/offer/" + offer.getListing().getId(),
                saved.getId(),
                counterMeta
        );

        log.info("Counter offer of Rs. {} submitted on offer '{}'", req.getCounterAmount(), offerId);
        return mapToDto(saved, currentUserId);
    }

    /**
     * Rejects or declines an offer.
     */
    @Transactional
    public OfferDto rejectOffer(UUID offerId, UUID currentUserId, com.bidly.offer.dto.RejectOfferRequest req) {
        Offer offer = offerRepository.findByIdWithPessimisticLock(offerId)
                .orElseThrow(() -> BidlyException.notFound("Offer not found: " + offerId));

        boolean isSeller = currentUserId.equals(offer.getSeller().getId());
        boolean isBuyer = currentUserId.equals(offer.getBuyer().getId());
        if (!isSeller && !isBuyer) {
            throw BidlyException.forbidden("You are not authorized to reject this offer");
        }

        if (isSeller) {
            offer.setStatus(Offer.OfferStatus.REJECTED);
            if (req != null) {
                offer.setRejectionReason(req.getReason());
                offer.setRejectionNote(req.getNote());
            }
            offer.setRejectedAt(Instant.now());
        } else {
            offer.setStatus(Offer.OfferStatus.CANCELLED);
        }
        Offer saved = offerRepository.save(offer);

        ChatRoom room = chatRoomRepository.findByListingIdAndBuyerId(offer.getListing().getId(), offer.getBuyer().getId()).orElse(null);
        if (room != null) {
            ChatMessage msg = new ChatMessage();
            msg.setRoomId(room.getId());
            msg.setSenderId(currentUserId);
            msg.setType(isSeller ? ChatMessage.MessageType.OFFER_REJECTED : ChatMessage.MessageType.SYSTEM);
            msg.setStatus(ChatMessage.MessageStatus.SENT);
            String reasonText = (req != null && req.getReason() != null && !req.getReason().isBlank()) ? " (" + req.getReason() + ")" : "";
            msg.setContent(isSeller ? "Offer of ₹" + offer.getAmount().toBigInteger() + " declined" + reasonText + "." : "Offer cancelled by buyer.");
            ChatMessage savedMsg = chatMessageRepository.save(msg);
            room.setLastMessageAt(Instant.now());
            room.setUpdatedAt(Instant.now());
            chatRoomRepository.save(room);

            String senderName = userRepository.findById(currentUserId).map(User::getName).orElse("User");
            broadcastOfferEvent(room.getId(), saved.getId(), saved.getStatus().name(), offer.getAmount().doubleValue(), null, savedMsg, senderName);
        }

        User rejectRecipient = isSeller ? offer.getBuyer() : offer.getSeller();
        String rejectMeta = String.format(
                "{\"reason\":\"%s\",\"note\":\"%s\",\"buyerId\":\"%s\",\"offerId\":\"%s\",\"buyerName\":\"%s\"}",
                req != null && req.getReason() != null ? req.getReason() : "",
                req != null && req.getNote() != null ? req.getNote() : "",
                offer.getBuyer().getId(), saved.getId(), offer.getBuyer().getName());

        notificationService.sendNotification(
                rejectRecipient,
                com.bidly.notification.entity.Notification.NotificationType.OFFER_REJECTED,
                isSeller ? "Offer Declined" : "Offer Cancelled",
                isSeller ? offer.getSeller().getName() + " declined your offer on " + offer.getListing().getTitle()
                         : offer.getBuyer().getName() + " cancelled their offer on " + offer.getListing().getTitle(),
                offer.getListing(),
                saved,
                null,
                "View Details",
                "/chat/offer/" + offer.getListing().getId(),
                saved.getId(),
                rejectMeta
        );

        return mapToDto(saved, currentUserId);
    }

    @Transactional
    public OfferDto rejectOffer(UUID offerId, UUID currentUserId) {
        return rejectOffer(offerId, currentUserId, null);
    }

    /**
     * Atomically accepts the offer, creates direct-sale order, cancels competing offers,
     * and notifies buyer via real-time WebSocket.
     */
    @Transactional
    public OfferDto acceptOffer(UUID offerId, UUID currentUserId, AcceptOfferRequest req) {
        Offer offer = offerRepository.findByIdWithPessimisticLock(offerId)
                .orElseThrow(() -> BidlyException.notFound("Offer not found: " + offerId));

        Listing listing = listingRepository.findByIdWithPessimisticLock(offer.getListing().getId())
                .orElseThrow(() -> BidlyException.notFound("Listing not found"));

        if (listing.getStatus() != Listing.ListingStatus.ACTIVE) {
            throw BidlyException.badRequest("This listing has already been sold or is no longer active");
        }

        if (listing.getSellingMethod() != Listing.SellingMethod.DIRECT_BUY) {
            throw BidlyException.badRequest("Listing is not a Direct Sale");
        }

        if (offer.getStatus() != Offer.OfferStatus.PENDING && offer.getStatus() != Offer.OfferStatus.COUNTERED) {
            throw BidlyException.badRequest("Cannot accept an offer that is " + offer.getStatus());
        }

        boolean isSeller = currentUserId.equals(offer.getSeller().getId());
        boolean isBuyer = currentUserId.equals(offer.getBuyer().getId());
        if (!isSeller && !isBuyer) {
            throw BidlyException.forbidden("Not authorized to accept this offer");
        }

        // Mark offer as ACCEPTED
        offer.setStatus(Offer.OfferStatus.ACCEPTED);
        Offer savedOffer = offerRepository.save(offer);

        // Create the Order with Delivery/Meetup configuration
        Order order = orderService.createOrderForAcceptedOffer(listing, savedOffer, req);

        // Cancel other pending offers on this listing
        List<Offer> pendingOffers = offerRepository.findByListingIdAndStatus(listing.getId(), Offer.OfferStatus.PENDING);
        for (Offer p : pendingOffers) {
            if (!p.getId().equals(offer.getId())) {
                p.setStatus(Offer.OfferStatus.CANCELLED);
                offerRepository.save(p);
            }
        }

        // Post accepted message to chat
        ChatRoom room = chatRoomRepository.findByListingIdAndBuyerId(listing.getId(), offer.getBuyer().getId()).orElse(null);
        if (room != null) {
            ChatMessage msg = new ChatMessage();
            msg.setRoomId(room.getId());
            msg.setSenderId(currentUserId);
            msg.setType(ChatMessage.MessageType.OFFER_ACCEPTED);
            msg.setStatus(ChatMessage.MessageStatus.SENT);
            msg.setContent("🎉 Offer accepted! Let's chat and meetup.");
            ChatMessage savedMsg = chatMessageRepository.save(msg);
            room.setLastMessageAt(Instant.now());
            room.setUpdatedAt(Instant.now());
            chatRoomRepository.save(room);

            String senderName = userRepository.findById(currentUserId).map(User::getName).orElse("User");
            broadcastOfferEvent(room.getId(), savedOffer.getId(), "ACCEPTED", offer.getAmount().doubleValue(), null, savedMsg, senderName);
        }

        // Send persistent notification & real-time alert to the other party
        User acceptRecipient = isSeller ? offer.getBuyer() : offer.getSeller();
        String acceptTitle = "Offer Accepted!";
        String acceptMsg = isSeller
                ? offer.getSeller().getName() + " accepted your offer on " + listing.getTitle()
                : offer.getBuyer().getName() + " accepted your counter-offer on " + listing.getTitle();
        String acceptMeta = String.format(
                "{\"orderId\":\"%s\",\"orderNumber\":\"%s\",\"buyerId\":\"%s\",\"offerId\":\"%s\",\"buyerName\":\"%s\"}",
                order.getId(), order.getOrderNumber(), offer.getBuyer().getId(), savedOffer.getId(), offer.getBuyer().getName());

        notificationService.sendNotification(
                acceptRecipient,
                com.bidly.notification.entity.Notification.NotificationType.OFFER_ACCEPTED,
                acceptTitle,
                acceptMsg,
                listing,
                savedOffer,
                order,
                "View Details",
                "/chat/offer/" + listing.getId(),
                order.getId(),
                acceptMeta
        );

        log.info("Offer '{}' accepted. Order '{}' created.", offerId, order.getOrderNumber());
        OfferDto dto = mapToDto(savedOffer, currentUserId);
        dto.setOrderId(order.getId());
        return dto;
    }

    private void broadcastOfferEvent(UUID roomId, UUID offerId, String status, Double amount, Double counterAmount, ChatMessage msg, String senderName) {
        if (TransactionSynchronizationManager.isSynchronizationActive()) {
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override
                public void afterCommit() {
                    try {
                        ChatEventDto event = ChatEventDto.offerUpdated(roomId, offerId, status, amount, counterAmount);
                        messagingTemplate.convertAndSend("/topic/chats/" + roomId, event);

                        ChatMessageDto msgDto = new ChatMessageDto();
                        msgDto.setId(msg.getId());
                        msgDto.setRoomId(roomId);
                        msgDto.setSenderId(msg.getSenderId());
                        msgDto.setSenderName(senderName);
                        msgDto.setContent(msg.getContent());
                        msgDto.setOfferAmount(msg.getOfferAmount());
                        msgDto.setType(msg.getType().name());
                        msgDto.setStatus(msg.getStatus().name());
                        msgDto.setCreatedAt(msg.getCreatedAt());

                        ChatEventDto newMsgEvent = ChatEventDto.newMessage(roomId, msgDto);
                        messagingTemplate.convertAndSend("/topic/chats/" + roomId, newMsgEvent);
                        log.info("[OFFER_WS] BROADCAST offerUpdated roomId={} offerId={} status={}", roomId, offerId, status);
                    } catch (Exception e) {
                        log.warn("[OFFER_WS] Failed to broadcast offer event: {}", e.getMessage());
                    }
                }
            });
        }
    }

    /**
     * Retrieves the latest offer for a listing + buyer.
     */
    @Transactional(readOnly = true)
    public Optional<OfferDto> getLatestOffer(UUID listingId, UUID buyerId, UUID currentUserId) {
        return offerRepository.findFirstByListingIdAndBuyerIdOrderByCreatedAtDesc(listingId, buyerId)
                .map(o -> mapToDto(o, currentUserId));
    }

    /**
     * Retrieves an offer by ID.
     */
    @Transactional(readOnly = true)
    public OfferDto getOfferById(UUID offerId, UUID currentUserId) {
        Offer offer = offerRepository.findById(offerId)
                .orElseThrow(() -> BidlyException.notFound("Offer not found: " + offerId));
        return mapToDto(offer, currentUserId);
    }

    public OfferDto mapToDto(Offer o, UUID currentUserId) {
        OfferDto dto = new OfferDto();
        dto.setId(o.getId());
        dto.setListingId(o.getListing().getId());
        dto.setListingTitle(o.getListing().getTitle());
        dto.setListingPrice(o.getListing().getPrice());

        String primaryImg = (o.getListing().getMedia() != null && !o.getListing().getMedia().isEmpty())
                ? o.getListing().getMedia().get(0).getUrl() : null;
        dto.setListingImageUrl(mediaService.generatePresignedGetUrl(primaryImg, Duration.ofHours(4)));

        dto.setBuyerId(o.getBuyer().getId());
        dto.setBuyerName(o.getBuyer().getName() != null ? o.getBuyer().getName() : "Buyer");
        dto.setBuyerAvatarUrl(o.getBuyer().getAvatarUrl());
        dto.setBuyerLocality(o.getBuyer().getCity() != null ? o.getBuyer().getCity() : (o.getListing().getLocality() != null ? o.getListing().getLocality() : "Chennai"));

        dto.setSellerId(o.getSeller().getId());
        dto.setSellerName(o.getSeller().getName() != null ? o.getSeller().getName() : "Seller");

        dto.setAmount(o.getAmount());
        dto.setCounterAmount(o.getCounterAmount());
        dto.setStatus(o.getStatus().name());
        dto.setMessage(o.getMessage());
        dto.setRejectionReason(o.getRejectionReason());
        dto.setRejectionNote(o.getRejectionNote());
        dto.setRejectedAt(o.getRejectedAt());
        dto.setCreatedAt(o.getCreatedAt());
        dto.setExpiresAt(o.getExpiresAt());

        orderRepository.findByOfferId(o.getId()).ifPresent(ord -> dto.setOrderId(ord.getId()));

        if (currentUserId != null) {
            dto.setBuyer(currentUserId.equals(o.getBuyer().getId()));
            dto.setSeller(currentUserId.equals(o.getSeller().getId()));
        }

        return dto;
    }
}
