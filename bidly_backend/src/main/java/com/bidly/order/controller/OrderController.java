package com.bidly.order.controller;

import com.bidly.common.dto.ApiResponse;
import com.bidly.order.dto.OrderSummaryDto;
import com.bidly.order.service.OrderService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/orders")
public class OrderController {

    private final OrderService orderService;

    public OrderController(OrderService orderService) {
        this.orderService = orderService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<java.util.List<OrderSummaryDto>>> getOrders(
            @AuthenticationPrincipal UUID currentUserId,
            @RequestParam(required = false) String source,
            @RequestParam(required = false) String role) {
        java.util.List<OrderSummaryDto> orders = orderService.getUserOrders(currentUserId, source, role);
        return ResponseEntity.ok(ApiResponse.success(orders));
    }

    @GetMapping("/{orderId}")
    public ResponseEntity<ApiResponse<OrderSummaryDto>> getOrder(
            @PathVariable UUID orderId,
            @AuthenticationPrincipal UUID currentUserId) {
        OrderSummaryDto dto = orderService.getOrderDetails(orderId, currentUserId);
        return ResponseEntity.ok(ApiResponse.success(dto));
    }

    @GetMapping("/listing/{listingId}")
    public ResponseEntity<ApiResponse<OrderSummaryDto>> getOrderByListing(
            @PathVariable UUID listingId,
            @AuthenticationPrincipal UUID currentUserId) {
        OrderSummaryDto dto = orderService.getOrCreateOrderByListing(listingId, currentUserId);
        return ResponseEntity.ok(ApiResponse.success(dto));
    }

    @PutMapping("/{orderId}/delivery-address")
    public ResponseEntity<ApiResponse<OrderSummaryDto>> updateDeliveryAddress(
            @PathVariable UUID orderId,
            @AuthenticationPrincipal UUID currentUserId,
            @RequestBody com.bidly.order.dto.UpdateOrderAddressRequest request) {
        OrderSummaryDto dto = orderService.updateDeliveryAddress(orderId, currentUserId, request);
        return ResponseEntity.ok(ApiResponse.success("Delivery address updated successfully", dto));
    }

    @PostMapping("/{orderId}/confirm-delivery")
    public ResponseEntity<ApiResponse<OrderSummaryDto>> confirmDelivery(
            @PathVariable UUID orderId,
            @AuthenticationPrincipal UUID currentUserId) {
        OrderSummaryDto dto = orderService.confirmDelivery(orderId, currentUserId);
        return ResponseEntity.ok(ApiResponse.success("Delivery confirmed and payout released to seller", dto));
    }

    @PostMapping("/{orderId}/schedule-meetup")
    public ResponseEntity<ApiResponse<OrderSummaryDto>> scheduleMeetup(
            @PathVariable UUID orderId,
            @AuthenticationPrincipal UUID currentUserId,
            @jakarta.validation.Valid @RequestBody com.bidly.order.dto.ScheduleMeetupRequest request) {
        OrderSummaryDto dto = orderService.scheduleMeetup(orderId, currentUserId, request);
        return ResponseEntity.ok(ApiResponse.success("Meetup scheduled successfully", dto));
    }

    @PostMapping("/{orderId}/courier-shipment")
    public ResponseEntity<ApiResponse<OrderSummaryDto>> createCourierShipment(
            @PathVariable UUID orderId,
            @AuthenticationPrincipal UUID currentUserId,
            @jakarta.validation.Valid @RequestBody com.bidly.order.dto.CourierShipmentRequest request) {
        OrderSummaryDto dto = orderService.createCourierShipment(orderId, currentUserId, request);
        return ResponseEntity.ok(ApiResponse.success("Shipment dispatched successfully", dto));
    }

    @GetMapping("/{orderId}/otp")
    public ResponseEntity<ApiResponse<com.bidly.order.dto.BuyerOtpDto>> getBuyerOtp(
            @PathVariable UUID orderId,
            @AuthenticationPrincipal UUID currentUserId) {
        com.bidly.order.dto.BuyerOtpDto dto = orderService.getBuyerOtp(orderId, currentUserId);
        return ResponseEntity.ok(ApiResponse.success(dto));
    }

    @PostMapping("/{orderId}/verify-otp")
    public ResponseEntity<ApiResponse<OrderSummaryDto>> verifyMeetupOtp(
            @PathVariable UUID orderId,
            @AuthenticationPrincipal UUID currentUserId,
            @RequestBody java.util.Map<String, String> body) {
        String otp = body != null ? body.get("otp") : null;
        OrderSummaryDto dto = orderService.verifyMeetupOtp(orderId, otp, currentUserId);
        return ResponseEntity.ok(ApiResponse.success("OTP verified successfully. Please mark item as sold.", dto));
    }

    @PostMapping("/{orderId}/mark-sold")
    public ResponseEntity<ApiResponse<com.bidly.order.dto.SaleSummaryDto>> markSold(
            @PathVariable UUID orderId,
            @AuthenticationPrincipal UUID currentUserId) {
        com.bidly.order.dto.SaleSummaryDto dto = orderService.markSold(orderId, currentUserId);
        return ResponseEntity.ok(ApiResponse.success("Product marked as sold successfully", dto));
    }

    @GetMapping("/{orderId}/sale-summary")
    public ResponseEntity<ApiResponse<com.bidly.order.dto.SaleSummaryDto>> getSaleSummary(
            @PathVariable UUID orderId,
            @AuthenticationPrincipal UUID currentUserId) {
        com.bidly.order.dto.SaleSummaryDto dto = orderService.getSaleSummary(orderId, currentUserId);
        return ResponseEntity.ok(ApiResponse.success(dto));
    }
}
