package com.bidly.notification.dto;

import com.bidly.notification.entity.Notification;

import java.time.Duration;
import java.time.Instant;
import java.util.UUID;

public class NotificationDto {

    private UUID id;
    private UUID userId;
    private String type;
    private String title;
    private String body;
    private boolean isRead;
    private UUID listingId;
    private UUID offerId;
    private UUID orderId;
    private String actionLabel;
    private String targetRoute;
    private UUID targetId;
    private String metadata;
    private Instant createdAt;
    private String timeAgo;

    public NotificationDto() {}

    public static NotificationDto fromEntity(Notification entity) {
        if (entity == null) return null;
        NotificationDto dto = new NotificationDto();
        dto.setId(entity.getId());
        dto.setUserId(entity.getUser() != null ? entity.getUser().getId() : null);
        dto.setType(entity.getType() != null ? entity.getType().name() : "OFFER");
        dto.setTitle(entity.getTitle());
        dto.setBody(entity.getBody());
        dto.setRead(entity.isRead());
        dto.setListingId(entity.getListing() != null ? entity.getListing().getId() : null);
        dto.setOfferId(entity.getOffer() != null ? entity.getOffer().getId() : null);
        dto.setOrderId(entity.getOrder() != null ? entity.getOrder().getId() : null);
        dto.setActionLabel(entity.getActionLabel());
        dto.setTargetRoute(entity.getTargetRoute());
        dto.setTargetId(entity.getTargetId());
        dto.setMetadata(entity.getMetadata());
        dto.setCreatedAt(entity.getCreatedAt());
        dto.setTimeAgo(formatTimeAgo(entity.getCreatedAt()));
        return dto;
    }

    private static String formatTimeAgo(Instant instant) {
        if (instant == null) return "Just now";
        Duration diff = Duration.between(instant, Instant.now());
        long seconds = diff.getSeconds();
        if (seconds < 60) return "Just now";
        long minutes = seconds / 60;
        if (minutes < 60) return minutes + "m ago";
        long hours = minutes / 60;
        if (hours < 24) return hours + "h ago";
        long days = hours / 24;
        return days + "d ago";
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getBody() { return body; }
    public void setBody(String body) { this.body = body; }

    public boolean isRead() { return isRead; }
    public void setRead(boolean read) { isRead = read; }

    public UUID getListingId() { return listingId; }
    public void setListingId(UUID listingId) { this.listingId = listingId; }

    public UUID getOfferId() { return offerId; }
    public void setOfferId(UUID offerId) { this.offerId = offerId; }

    public UUID getOrderId() { return orderId; }
    public void setOrderId(UUID orderId) { this.orderId = orderId; }

    public String getActionLabel() { return actionLabel; }
    public void setActionLabel(String actionLabel) { this.actionLabel = actionLabel; }

    public String getTargetRoute() { return targetRoute; }
    public void setTargetRoute(String targetRoute) { this.targetRoute = targetRoute; }

    public UUID getTargetId() { return targetId; }
    public void setTargetId(UUID targetId) { this.targetId = targetId; }

    public String getMetadata() { return metadata; }
    public void setMetadata(String metadata) { this.metadata = metadata; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }

    public String getTimeAgo() { return timeAgo; }
    public void setTimeAgo(String timeAgo) { this.timeAgo = timeAgo; }
}
