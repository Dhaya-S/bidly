package com.bidly.order.dto;

import java.util.UUID;

public class UpdateOrderAddressRequest {
    private UUID addressId;
    private String fullName;
    private String phone;
    private String addressLine;
    private String city;
    private String pincode;

    public UpdateOrderAddressRequest() {}

    public UpdateOrderAddressRequest(UUID addressId, String fullName, String phone, String addressLine, String city, String pincode) {
        this.addressId = addressId;
        this.fullName = fullName;
        this.phone = phone;
        this.addressLine = addressLine;
        this.city = city;
        this.pincode = pincode;
    }

    public UUID getAddressId() { return addressId; }
    public void setAddressId(UUID addressId) { this.addressId = addressId; }

    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }

    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }

    public String getAddressLine() { return addressLine; }
    public void setAddressLine(String addressLine) { this.addressLine = addressLine; }

    public String getCity() { return city; }
    public void setCity(String city) { this.city = city; }

    public String getPincode() { return pincode; }
    public void setPincode(String pincode) { this.pincode = pincode; }
}
