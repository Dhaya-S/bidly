package com.bidly.notification.service;

import com.bidly.common.exception.BidlyException;
import com.bidly.listing.entity.Listing;
import com.bidly.notification.dto.NotificationDto;
import com.bidly.notification.entity.Notification;
import com.bidly.notification.repository.NotificationRepository;
import com.bidly.offer.entity.Offer;
import com.bidly.order.entity.Order;
import com.bidly.user.entity.User;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class NotificationService {

    private static final Logger log = LoggerFactory.getLogger(NotificationService.class);

    private final NotificationRepository notificationRepository;
    private final SimpMessagingTemplate messagingTemplate;

    public NotificationService(
            NotificationRepository notificationRepository,
            SimpMessagingTemplate messagingTemplate) {
        this.notificationRepository = notificationRepository;
        this.messagingTemplate = messagingTemplate;
    }

    /**
     * Persists a notification to the database and schedules a post-commit WebSocket broadcast.
     */
    @Transactional
    public Notification sendNotification(
            User recipient,
            Notification.NotificationType type,
            String title,
            String body,
            Listing listing,
            Offer offer,
            Order order,
            String actionLabel,
            String targetRoute,
            UUID targetId,
            String metadataJson) {

        if (recipient == null) {
            log.warn("Cannot send notification: recipient is null (title='{}')", title);
            return null;
        }

        Notification notification = new Notification();
        notification.setUser(recipient);
        notification.setType(type);
        notification.setTitle(title);
        notification.setBody(body);
        notification.setRead(false);
        notification.setListing(listing);
        notification.setOffer(offer);
        notification.setOrder(order);
        notification.setActionLabel(actionLabel);
        notification.setTargetRoute(targetRoute);
        notification.setTargetId(targetId);
        notification.setMetadata(metadataJson);

        Notification saved = notificationRepository.save(notification);
        final NotificationDto dto = NotificationDto.fromEntity(saved);
        final UUID userId = recipient.getId();

        // Ensure real-time STOMP broadcast happens ONLY after database transaction commits
        if (TransactionSynchronizationManager.isActualTransactionActive()) {
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override
                public void afterCommit() {
                    broadcastNotification(userId, dto);
                }
            });
        } else {
            broadcastNotification(userId, dto);
        }

        log.info("[NOTIFICATION] Created notification {} of type {} for user {}", saved.getId(), type, recipient.getId());
        return saved;
    }

    @Transactional
    public Notification sendNotificationWithMeta(
            User recipient,
            Notification.NotificationType type,
            String title,
            String body,
            Listing listing,
            Offer offer,
            Order order,
            String actionLabel,
            String targetRoute,
            UUID targetId,
            Map<String, ?> metadataMap) {
        String metadataJson = null;
        if (metadataMap != null) {
            try {
                metadataJson = new com.fasterxml.jackson.databind.ObjectMapper().writeValueAsString(metadataMap);
            } catch (Exception e) {
                log.warn("Failed to serialize metadata for notification: {}", e.getMessage());
            }
        }
        return sendNotification(recipient, type, title, body, listing, offer, order, actionLabel, targetRoute, targetId, metadataJson);
    }

    private void broadcastNotification(UUID userId, NotificationDto dto) {
        try {
            long unreadCount = notificationRepository.countByUserIdAndReadFalse(userId);
            Map<String, Object> payload = new HashMap<>();
            payload.put("eventType", dto.getType());
            payload.put("notification", dto);
            payload.put("unreadCount", unreadCount);

            // Broadcast to primary user notification topic
            messagingTemplate.convertAndSend("/topic/users/" + userId + "/notifications", (Object) payload);
            // Also broadcast to user chat stream for instant badge/sync
            messagingTemplate.convertAndSend("/topic/users/" + userId + "/chat", (Object) payload);

            log.info("[NOTIFICATION_WS] Dispatched {} to /topic/users/{}/notifications (unread={})",
                    dto.getType(), userId, unreadCount);
        } catch (Exception e) {
            log.error("[NOTIFICATION_WS] Failed to broadcast notification event to user {}: {}", userId, e.getMessage());
        }
    }

    @Transactional(readOnly = true)
    public List<NotificationDto> getUserNotifications(UUID userId) {
        return notificationRepository.findByUserIdOrderByCreatedAtDesc(userId).stream()
                .map(NotificationDto::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public long getUnreadCount(UUID userId) {
        return notificationRepository.countByUserIdAndReadFalse(userId);
    }

    @Transactional
    public void markAsRead(UUID notificationId, UUID userId) {
        int updated = notificationRepository.markAsRead(notificationId, userId);
        if (updated == 0) {
            log.debug("No unread notification found with id {} for user {}", notificationId, userId);
        }
    }

    @Transactional
    public void markAllAsRead(UUID userId) {
        notificationRepository.markAllAsReadForUser(userId);
        log.info("Marked all notifications read for user {}", userId);
    }
}
