package com.bidly.order.repository;

import com.bidly.order.entity.Order;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface OrderRepository extends JpaRepository<Order, UUID> {

    @EntityGraph(attributePaths = {"listing", "buyer", "seller", "deliveryAddress"})
    Optional<Order> findByOrderNumber(String orderNumber);

    @EntityGraph(attributePaths = {"listing", "buyer", "seller", "deliveryAddress"})
    Optional<Order> findFirstByListingIdOrderByCreatedAtDesc(UUID listingId);

    @EntityGraph(attributePaths = {"listing", "buyer", "seller", "deliveryAddress"})
    Optional<Order> findFirstByListingIdAndBuyerIdOrderByCreatedAtDesc(UUID listingId, UUID buyerId);

    @EntityGraph(attributePaths = {"listing", "buyer", "seller", "deliveryAddress"})
    Optional<Order> findFirstByListingIdAndSellerIdOrderByCreatedAtDesc(UUID listingId, UUID sellerId);

    @EntityGraph(attributePaths = {"listing", "buyer", "seller", "deliveryAddress"})
    Optional<Order> findByOfferId(UUID offerId);

    @EntityGraph(attributePaths = {"listing", "buyer", "seller"})
    List<Order> findByBuyerIdOrderByCreatedAtDesc(UUID buyerId);

    @EntityGraph(attributePaths = {"listing", "buyer", "seller"})
    List<Order> findBySellerIdOrderByCreatedAtDesc(UUID sellerId);

    Optional<Order> findByClientActionId(String clientActionId);

    @org.springframework.data.jpa.repository.Lock(jakarta.persistence.LockModeType.PESSIMISTIC_WRITE)
    @org.springframework.data.jpa.repository.Query("SELECT o FROM Order o WHERE o.id = :id")
    Optional<Order> findByIdWithPessimisticLock(@org.springframework.data.repository.query.Param("id") UUID id);
}
