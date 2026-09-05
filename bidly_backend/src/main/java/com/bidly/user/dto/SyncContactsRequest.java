package com.bidly.user.dto;

import java.util.List;

public class SyncContactsRequest {
    private List<String> phoneNumbers;

    public List<String> getPhoneNumbers() {
        return phoneNumbers;
    }

    public void setPhoneNumbers(List<String> phoneNumbers) {
        this.phoneNumbers = phoneNumbers;
    }
}
