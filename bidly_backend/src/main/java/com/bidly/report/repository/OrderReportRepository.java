package com.bidly.report.repository;

import com.bidly.report.entity.OrderReport;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface OrderReportRepository extends JpaRepository<OrderReport, UUID> {
    List<OrderReport> findByOrderId(UUID orderId);
    List<OrderReport> findByReporterId(UUID reporterId);
}
