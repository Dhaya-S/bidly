package com.bidly.order.dto;

import java.time.Instant;
import java.util.UUID;

public class BuyerOtpDto {

    private UUID orderId;
    private String orderNumber;
    private String otp;
    private Instant otpExpiresAt;
    private String buyerName;
    private String sellerName;
    private String productTitle;
    private String productImageUrl;
    private String meetupLocation;
    private Instant meetupTime;
    private String meetupDateFormatted;
    private String meetupTimeFormatted;

    public BuyerOtpDto() {}

    public UUID getOrderId() { return orderId; }
    public void setOrderId(UUID orderId) { this.orderId = orderId; }

    public String getOrderNumber() { return orderNumber; }
    public void setOrderNumber(String orderNumber) { this.orderNumber = orderNumber; }

    public String getOtp() { return otp; }
    public void setOtp(String otp) { this.otp = otp; }

    public Instant getOtpExpiresAt() { return otpExpiresAt; }
    public void setOtpExpiresAt(Instant otpExpiresAt) { this.otpExpiresAt = otpExpiresAt; }

    public String getBuyerName() { return buyerName; }
    public void setBuyerName(String buyerName) { this.buyerName = buyerName; }

    public String getSellerName() { return sellerName; }
    public void setSellerName(String sellerName) { this.sellerName = sellerName; }

    public String getProductTitle() { return productTitle; }
    public void setProductTitle(String productTitle) { this.productTitle = productTitle; }

    public String getProductImageUrl() { return productImageUrl; }
    public void setProductImageUrl(String productImageUrl) { this.productImageUrl = productImageUrl; }

    public String getMeetupLocation() { return meetupLocation; }
    public void setMeetupLocation(String meetupLocation) { this.meetupLocation = meetupLocation; }

    public Instant getMeetupTime() { return meetupTime; }
    public void setMeetupTime(Instant meetupTime) { this.meetupTime = meetupTime; }

    public String getMeetupDateFormatted() { return meetupDateFormatted; }
    public void setMeetupDateFormatted(String meetupDateFormatted) { this.meetupDateFormatted = meetupDateFormatted; }

    public String getMeetupTimeFormatted() { return meetupTimeFormatted; }
    public void setMeetupTimeFormatted(String meetupTimeFormatted) { this.meetupTimeFormatted = meetupTimeFormatted; }
}
