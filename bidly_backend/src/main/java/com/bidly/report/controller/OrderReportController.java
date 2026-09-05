package com.bidly.report.controller;

import com.bidly.common.dto.ApiResponse;
import com.bidly.report.dto.CreateReportRequest;
import com.bidly.report.dto.OrderReportDto;
import com.bidly.report.service.OrderReportService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/reports")
public class OrderReportController {

    private final OrderReportService reportService;

    public OrderReportController(OrderReportService reportService) {
        this.reportService = reportService;
    }

    @PostMapping
    public ResponseEntity<ApiResponse<OrderReportDto>> submitReport(
            @AuthenticationPrincipal UUID currentUserId,
            @Valid @RequestBody CreateReportRequest request) {
        OrderReportDto report = reportService.createReport(currentUserId, request);
        return ResponseEntity.ok(ApiResponse.success("Report submitted successfully. Our team will review within 24 hours.", report));
    }
}
