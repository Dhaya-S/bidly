package com.bidly.auction.dto;

import java.math.BigDecimal;
import java.util.UUID;

public class AuctionWinnerDto {

    private UUID orderId;
    private UUID listingId;
    private String listingTitle;
    private String listingImageUrl;
    private UUID winnerId;
    private String winnerName;
    private String winnerLocality;
    private BigDecimal winningAmount;
    private boolean paymentSecuredInEscrow;
    private String orderStatus;

    public AuctionWinnerDto() {}

    public AuctionWinnerDto(UUID orderId, UUID listingId, String listingTitle, String listingImageUrl,
                            UUID winnerId, String winnerName, String winnerLocality,
                            BigDecimal winningAmount, boolean paymentSecuredInEscrow, String orderStatus) {
        this.orderId = orderId;
        this.listingId = listingId;
        this.listingTitle = listingTitle;
        this.listingImageUrl = listingImageUrl;
        this.winnerId = winnerId;
        this.winnerName = winnerName;
        this.winnerLocality = winnerLocality;
        this.winningAmount = winningAmount;
        this.paymentSecuredInEscrow = paymentSecuredInEscrow;
        this.orderStatus = orderStatus;
    }

    public UUID getOrderId() { return orderId; }
    public void setOrderId(UUID orderId) { this.orderId = orderId; }

    public UUID getListingId() { return listingId; }
    public void setListingId(UUID listingId) { this.listingId = listingId; }

    public String getListingTitle() { return listingTitle; }
    public void setListingTitle(String listingTitle) { this.listingTitle = listingTitle; }

    public String getListingImageUrl() { return listingImageUrl; }
    public void setListingImageUrl(String listingImageUrl) { this.listingImageUrl = listingImageUrl; }

    public UUID getWinnerId() { return winnerId; }
    public void setWinnerId(UUID winnerId) { this.winnerId = winnerId; }

    public String getWinnerName() { return winnerName; }
    public void setWinnerName(String winnerName) { this.winnerName = winnerName; }

    public String getWinnerLocality() { return winnerLocality; }
    public void setWinnerLocality(String winnerLocality) { this.winnerLocality = winnerLocality; }

    public BigDecimal getWinningAmount() { return winningAmount; }
    public void setWinningAmount(BigDecimal winningAmount) { this.winningAmount = winningAmount; }

    public boolean isPaymentSecuredInEscrow() { return paymentSecuredInEscrow; }
    public void setPaymentSecuredInEscrow(boolean paymentSecuredInEscrow) { this.paymentSecuredInEscrow = paymentSecuredInEscrow; }

    public String getOrderStatus() { return orderStatus; }
    public void setOrderStatus(String orderStatus) { this.orderStatus = orderStatus; }
}
