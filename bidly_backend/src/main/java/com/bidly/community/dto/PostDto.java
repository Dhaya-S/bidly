package com.bidly.community.dto;

import com.bidly.listing.dto.ListingSummaryDto;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.Collections;
import java.util.List;
import java.util.UUID;

public class PostDto {
    private UUID id;
    private UUID authorId;
    private String authorName;
    private String authorAvatarUrl;
    private UUID communityId;
    private String communityName;
    private String content;
    private String mediaUrl;
    private String mediaType;
    private String videoUrl;
    private String reelUrl;
    private String tag; // SELLING, ANNOUNCEMENT, REVIEW, GENERAL
    private int likesCount;
    private int sharesCount;

    @com.fasterxml.jackson.annotation.JsonProperty("isLikedByMe")
    private boolean isLikedByMe;

    @com.fasterxml.jackson.annotation.JsonProperty("likedByMe")
    public boolean getLikedByMe() {
        return isLikedByMe;
    }

    private Instant createdAt;

    // Instagram-style rich media items & optional linked listing details
    private List<ListingSummaryDto.MediaItemDto> mediaItems = Collections.emptyList();
    private UUID listingId;
    private String sellingMethod;
    private BigDecimal price;
    private BigDecimal startingBid;
    private BigDecimal currentBid;
    private Instant auctionEndTime;
    private Integer bidsCount;
    private String listingTitle;
    private String listingDescription;
    private Double distanceKm;
    private Double latitude;
    private Double longitude;
    private String locality;
    private String city;

    public PostDto() {}

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public UUID getAuthorId() { return authorId; }
    public void setAuthorId(UUID authorId) { this.authorId = authorId; }

    public String getAuthorName() { return authorName; }
    public void setAuthorName(String authorName) { this.authorName = authorName; }

    public String getAuthorAvatarUrl() { return authorAvatarUrl; }
    public void setAuthorAvatarUrl(String authorAvatarUrl) { this.authorAvatarUrl = authorAvatarUrl; }

    public UUID getCommunityId() { return communityId; }
    public void setCommunityId(UUID communityId) { this.communityId = communityId; }

    public String getCommunityName() { return communityName; }
    public void setCommunityName(String communityName) { this.communityName = communityName; }

    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }

    public String getMediaUrl() { return mediaUrl; }
    public void setMediaUrl(String mediaUrl) { this.mediaUrl = mediaUrl; }

    public String getMediaType() { return mediaType; }
    public void setMediaType(String mediaType) { this.mediaType = mediaType; }

    public String getVideoUrl() { return videoUrl; }
    public void setVideoUrl(String videoUrl) { this.videoUrl = videoUrl; }

    public String getReelUrl() { return reelUrl; }
    public void setReelUrl(String reelUrl) { this.reelUrl = reelUrl; }

    public String getTag() { return tag; }
    public void setTag(String tag) { this.tag = tag; }

    public int getLikesCount() { return likesCount; }
    public void setLikesCount(int likesCount) { this.likesCount = likesCount; }

    public int getSharesCount() { return sharesCount; }
    public void setSharesCount(int sharesCount) { this.sharesCount = sharesCount; }

    public boolean isLikedByMe() { return isLikedByMe; }
    public void setLikedByMe(boolean likedByMe) { isLikedByMe = likedByMe; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }

    public List<ListingSummaryDto.MediaItemDto> getMediaItems() { return mediaItems; }
    public void setMediaItems(List<ListingSummaryDto.MediaItemDto> mediaItems) { this.mediaItems = mediaItems; }

    public UUID getListingId() { return listingId; }
    public void setListingId(UUID listingId) { this.listingId = listingId; }

    public String getSellingMethod() { return sellingMethod; }
    public void setSellingMethod(String sellingMethod) { this.sellingMethod = sellingMethod; }

    public BigDecimal getPrice() { return price; }
    public void setPrice(BigDecimal price) { this.price = price; }

    public BigDecimal getStartingBid() { return startingBid; }
    public void setStartingBid(BigDecimal startingBid) { this.startingBid = startingBid; }

    public BigDecimal getCurrentBid() { return currentBid; }
    public void setCurrentBid(BigDecimal currentBid) { this.currentBid = currentBid; }

    public Instant getAuctionEndTime() { return auctionEndTime; }
    public void setAuctionEndTime(Instant auctionEndTime) { this.auctionEndTime = auctionEndTime; }

    public Integer getBidsCount() { return bidsCount; }
    public void setBidsCount(Integer bidsCount) { this.bidsCount = bidsCount; }

    public String getListingTitle() { return listingTitle; }
    public void setListingTitle(String listingTitle) { this.listingTitle = listingTitle; }

    public String getListingDescription() { return listingDescription; }
    public void setListingDescription(String listingDescription) { this.listingDescription = listingDescription; }

    public Double getDistanceKm() { return distanceKm; }
    public void setDistanceKm(Double distanceKm) { this.distanceKm = distanceKm; }

    public Double getLatitude() { return latitude; }
    public void setLatitude(Double latitude) { this.latitude = latitude; }

    public Double getLongitude() { return longitude; }
    public void setLongitude(Double longitude) { this.longitude = longitude; }

    public String getLocality() { return locality; }
    public void setLocality(String locality) { this.locality = locality; }

    public String getCity() { return city; }
    public void setCity(String city) { this.city = city; }
}
