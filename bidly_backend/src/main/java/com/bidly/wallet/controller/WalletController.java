package com.bidly.wallet.controller;

import com.bidly.common.dto.ApiResponse;
import com.bidly.wallet.dto.WalletDto;
import com.bidly.wallet.service.WalletService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/wallet")
public class WalletController {

    private final WalletService walletService;

    public WalletController(WalletService walletService) {
        this.walletService = walletService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<WalletDto>> getWallet(@AuthenticationPrincipal UUID currentUserId) {
        WalletDto dto = walletService.getWallet(currentUserId);
        return ResponseEntity.ok(ApiResponse.success(dto));
    }

    /**
     * Development / Demo top-up endpoint so tester can add bidding funds if balance is low
     */
    @PostMapping("/top-up")
    public ResponseEntity<ApiResponse<WalletDto>> topUp(
            @AuthenticationPrincipal UUID currentUserId,
            @RequestBody Map<String, Object> body) {
        BigDecimal amount = new BigDecimal(body.getOrDefault("amount", "10000").toString());
        String desc = (String) body.getOrDefault("description", "Demo wallet top-up");
        WalletDto dto = walletService.topUpFunds(currentUserId, amount, desc);
        return ResponseEntity.ok(ApiResponse.success("Funds added successfully", dto));
    }
}
