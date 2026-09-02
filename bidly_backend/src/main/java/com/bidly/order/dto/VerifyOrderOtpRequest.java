package com.bidly.order.dto;

import jakarta.validation.constraints.NotBlank;

public class VerifyOrderOtpRequest {

    @NotBlank(message = "OTP code is required")
    private String otp;

    public VerifyOrderOtpRequest() {}

    public VerifyOrderOtpRequest(String otp) {
        this.otp = otp;
    }

    public String getOtp() { return otp; }
    public void setOtp(String otp) { this.otp = otp; }
}
