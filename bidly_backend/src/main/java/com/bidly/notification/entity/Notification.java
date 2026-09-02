package com.bidly.notification.entity;

import com.bidly.common.entity.BaseEntity;
import com.bidly.listing.entity.Listing;
import com.bidly.offer.entity.Offer;
import com.bidly.order.entity.Order;
import com.bidly.user.entity.User;
import jakarta.persistence.*;

import java.util.UUID;

@Entity
@Table(name = "notifications", indexes = {
        @Index(name = "idx_notifications_user_created", columnList = "user_id, created_at DESC"),
        @Index(name = "idx_notifications_user_unread", columnList = "user_id, is_read, created_at DESC"),
        @Index(name = "idx_notifications_offer", columnList = "offer_id"),
        @Index(name = "idx_notifications_order", columnList = "order_id"),
        @Index(name = "idx_notifications_listing", columnList = "listing_id")
})
public class Notification extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 50)
    private NotificationType type;

    @Column(nullable = false, length = 200)
    private String title;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String body;

    @Column(name = "is_read", nullable = false)
    private boolean read = false;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "listing_id")
    private Listing listing;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "offer_id")
    private Offer offer;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "order_id")
    private Order order;

    @Column(name = "action_label", length = 100)
    private String actionLabel;

    @Column(name = "target_route", length = 255)
    private String targetRoute;

    @Column(name = "target_id")
    private UUID targetId;

    @Column(columnDefinition = "TEXT")
    private String metadata;

    public enum NotificationType {
        NEW_OFFER,
        OFFER_ACCEPTED,
        OFFER_REJECTED,
        MEETUP_SCHEDULED,
        OTP_READY,
        OTP_VERIFIED,
        TRANSACTION_COMPLETED,
        ITEM_SOLD,
        AUCTION_WON,
        WINNER_SELECTED,
        SHIPPED
    }

    public Notification() {}

    public Notification(User user, NotificationType type, String title, String body) {
        this.user = user;
        this.type = type;
        this.title = title;
        this.body = body;
        this.read = false;
    }

    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }

    public NotificationType getType() { return type; }
    public void setType(NotificationType type) { this.type = type; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getBody() { return body; }
    public void setBody(String body) { this.body = body; }

    public boolean isRead() { return read; }
    public void setRead(boolean read) { this.read = read; }

    public Listing getListing() { return listing; }
    public void setListing(Listing listing) { this.listing = listing; }

    public Offer getOffer() { return offer; }
    public void setOffer(Offer offer) { this.offer = offer; }

    public Order getOrder() { return order; }
    public void setOrder(Order order) { this.order = order; }

    public String getActionLabel() { return actionLabel; }
    public void setActionLabel(String actionLabel) { this.actionLabel = actionLabel; }

    public String getTargetRoute() { return targetRoute; }
    public void setTargetRoute(String targetRoute) { this.targetRoute = targetRoute; }

    public UUID getTargetId() { return targetId; }
    public void setTargetId(UUID targetId) { this.targetId = targetId; }

    public String getMetadata() { return metadata; }
    public void setMetadata(String metadata) { this.metadata = metadata; }
}
