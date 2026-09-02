package com.bidly.chat.dto;

import java.util.UUID;

public class CreateRoomRequest {
    private UUID listingId;
    private UUID buyerId;
    private UUID offerId;

    public UUID getListingId() { return listingId; }
    public void setListingId(UUID listingId) { this.listingId = listingId; }

    public UUID getBuyerId() { return buyerId; }
    public void setBuyerId(UUID buyerId) { this.buyerId = buyerId; }

    public UUID getOfferId() { return offerId; }
    public void setOfferId(UUID offerId) { this.offerId = offerId; }
}
