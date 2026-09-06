package com.bidly.listing.dto;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

public class UpdateListingRequest {

    private String category;
    private String subcategory;
    private String title;
    private String purchaseDate;
    private String description;
    private BigDecimal price;
    private String condition;
    private Boolean hasDamage;
    private String damageDetails;
    private String sellingScope;
    private java.util.UUID communityId;
    private String communityName;
    private Integer targetRadiusKm;
    private String reelUrl;
    private List<String> mediaUrls = new ArrayList<>();
    private String city;
    private String state;
    private String locality;

    public UpdateListingRequest() {}

    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }

    public String getSubcategory() { return subcategory; }
    public void setSubcategory(String subcategory) { this.subcategory = subcategory; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getPurchaseDate() { return purchaseDate; }
    public void setPurchaseDate(String purchaseDate) { this.purchaseDate = purchaseDate; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public BigDecimal getPrice() { return price; }
    public void setPrice(BigDecimal price) { this.price = price; }

    public String getCondition() { return condition; }
    public void setCondition(String condition) { this.condition = condition; }

    public Boolean getHasDamage() { return hasDamage; }
    public void setHasDamage(Boolean hasDamage) { this.hasDamage = hasDamage; }

    public String getDamageDetails() { return damageDetails; }
    public void setDamageDetails(String damageDetails) { this.damageDetails = damageDetails; }

    public String getSellingScope() { return sellingScope; }
    public void setSellingScope(String sellingScope) { this.sellingScope = sellingScope; }

    public java.util.UUID getCommunityId() { return communityId; }
    public void setCommunityId(java.util.UUID communityId) { this.communityId = communityId; }

    public String getCommunityName() { return communityName; }
    public void setCommunityName(String communityName) { this.communityName = communityName; }

    public Integer getTargetRadiusKm() { return targetRadiusKm; }
    public void setTargetRadiusKm(Integer targetRadiusKm) { this.targetRadiusKm = targetRadiusKm; }

    public String getReelUrl() { return reelUrl; }
    public void setReelUrl(String reelUrl) { this.reelUrl = reelUrl; }

    public List<String> getMediaUrls() { return mediaUrls; }
    public void setMediaUrls(List<String> mediaUrls) { this.mediaUrls = mediaUrls; }

    public String getCity() { return city; }
    public void setCity(String city) { this.city = city; }

    public String getState() { return state; }
    public void setState(String state) { this.state = state; }

    public String getLocality() { return locality; }
    public void setLocality(String locality) { this.locality = locality; }
}
