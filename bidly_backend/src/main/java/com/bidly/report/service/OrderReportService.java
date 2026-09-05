package com.bidly.report.service;

import com.bidly.common.exception.BidlyException;
import com.bidly.order.entity.Order;
import com.bidly.order.repository.OrderRepository;
import com.bidly.report.dto.CreateReportRequest;
import com.bidly.report.dto.OrderReportDto;
import com.bidly.report.entity.OrderReport;
import com.bidly.report.repository.OrderReportRepository;
import com.bidly.user.entity.User;
import com.bidly.user.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
public class OrderReportService {

    private static final Logger log = LoggerFactory.getLogger(OrderReportService.class);

    private final OrderReportRepository reportRepository;
    private final OrderRepository orderRepository;
    private final UserRepository userRepository;

    public OrderReportService(
            OrderReportRepository reportRepository,
            OrderRepository orderRepository,
            UserRepository userRepository) {
        this.reportRepository = reportRepository;
        this.orderRepository = orderRepository;
        this.userRepository = userRepository;
    }

    @Transactional
    public OrderReportDto createReport(UUID reporterId, CreateReportRequest req) {
        Order order = orderRepository.findById(req.getOrderId())
                .orElseThrow(() -> BidlyException.notFound("Order not found: " + req.getOrderId()));

        User reporter = userRepository.findById(reporterId)
                .orElseThrow(() -> BidlyException.notFound("User not found: " + reporterId));

        OrderReport report = new OrderReport(order, reporter, req.getReason(), req.getDetails());
        OrderReport saved = reportRepository.save(report);

        log.info("[REPORT] Problem report {} created for order {} by user {} reason='{}'",
                saved.getId(), order.getId(), reporterId, req.getReason());

        OrderReportDto dto = new OrderReportDto();
        dto.setId(saved.getId());
        dto.setOrderId(order.getId());
        dto.setReporterId(reporter.getId());
        dto.setReason(saved.getReason());
        dto.setDetails(saved.getDetails());
        dto.setStatus(saved.getStatus());
        dto.setCreatedAt(saved.getCreatedAt());
        return dto;
    }
}
