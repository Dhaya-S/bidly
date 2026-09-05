package com.bidly.report.entity;

import com.bidly.common.entity.BaseEntity;
import com.bidly.order.entity.Order;
import com.bidly.user.entity.User;
import jakarta.persistence.*;

@Entity
@Table(name = "order_reports", indexes = {
        @Index(name = "idx_reports_order", columnList = "order_id"),
        @Index(name = "idx_reports_reporter", columnList = "reporter_id")
})
public class OrderReport extends BaseEntity {

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "order_id", nullable = false)
    private Order order;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "reporter_id", nullable = false)
    private User reporter;

    @Column(nullable = false)
    private String reason;

    @Column(columnDefinition = "TEXT")
    private String details;

    @Column(nullable = false)
    private String status = "PENDING_REVIEW";

    public OrderReport() {}

    public OrderReport(Order order, User reporter, String reason, String details) {
        this.order = order;
        this.reporter = reporter;
        this.reason = reason;
        this.details = details != null ? details.trim() : "";
        this.status = "PENDING_REVIEW";
    }

    public Order getOrder() { return order; }
    public void setOrder(Order order) { this.order = order; }

    public User getReporter() { return reporter; }
    public void setReporter(User reporter) { this.reporter = reporter; }

    public String getReason() { return reason; }
    public void setReason(String reason) { this.reason = reason; }

    public String getDetails() { return details; }
    public void setDetails(String details) { this.details = details; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
}
