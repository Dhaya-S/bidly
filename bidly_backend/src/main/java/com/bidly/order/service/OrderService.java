package com.bidly.order.service;

import com.bidly.auction.entity.Bid;
import com.bidly.common.exception.BidlyException;
import com.bidly.listing.entity.Listing;
import com.bidly.media.service.MediaService;
import com.bidly.order.dto.OrderSummaryDto;
import com.bidly.order.dto.OrderTrackingEventDto;
import com.bidly.order.entity.Order;
import com.bidly.order.entity.OrderTrackingEvent;
import com.bidly.order.repository.OrderRepository;
import com.bidly.order.repository.OrderTrackingEventRepository;
import com.bidly.wallet.service.WalletService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class OrderService {

    private final OrderRepository orderRepository;
    private final OrderTrackingEventRepository trackingEventRepository;
    private final WalletService walletService;
    private final MediaService mediaService;

    private final com.bidly.address.repository.DeliveryAddressRepository addressRepository;

    public OrderService(
            OrderRepository orderRepository,
            OrderTrackingEventRepository trackingEventRepository,
            WalletService walletService,
            MediaService mediaService,
            com.bidly.address.repository.DeliveryAddressRepository addressRepository) {
        this.orderRepository = orderRepository;
        this.trackingEventRepository = trackingEventRepository;
        this.walletService = walletService;
        this.mediaService = mediaService;
        this.addressRepository = addressRepository;
    }

    /**
     * Creates an Order when a Direct Sale offer is accepted.
     */
    @Transactional
    public Order createOrderForAcceptedOffer(Listing listing, com.bidly.offer.entity.Offer offer, com.bidly.offer.dto.AcceptOfferRequest req) {
        Optional<Order> existing = orderRepository.findByOfferId(offer.getId());
        if (existing.isPresent()) {
            return existing.get();
        }

        String orderNum = "ORD-2026-" + String.format("%05d", new Random().nextInt(90000) + 10000);
        BigDecimal agreedAmount = offer.getCounterAmount() != null ? offer.getCounterAmount() : offer.getAmount();
        BigDecimal platformFee = agreedAmount.multiply(BigDecimal.valueOf(0.02)).setScale(0, RoundingMode.HALF_UP);
        BigDecimal totalAmount = agreedAmount.add(platformFee);

        Order.DeliveryType deliveryType = "IN_PERSON_MEETUP".equalsIgnoreCase(req != null ? req.getDeliveryType() : "COURIER")
                ? Order.DeliveryType.IN_PERSON_MEETUP
                : Order.DeliveryType.COURIER;

        com.bidly.address.entity.DeliveryAddress address = null;
        if (req != null && req.getAddressId() != null) {
            address = addressRepository.findById(req.getAddressId()).orElse(null);
        }

        Order order = new Order();
        order.setOrderNumber(orderNum);
        order.setListing(listing);
        order.setBuyer(offer.getBuyer());
        order.setSeller(offer.getSeller());
        order.setOffer(offer);
        order.setOrderSource(Order.OrderSource.DIRECT_SALE);
        order.setDeliveryType(deliveryType);
        order.setDeliveryAddress(address);
        order.setAmount(agreedAmount);
        order.setPlatformFee(platformFee);
        order.setTotalAmount(totalAmount);
        order.setPaymentStatus(Order.PaymentStatus.IN_ESCROW);

        if (deliveryType == Order.DeliveryType.IN_PERSON_MEETUP) {
            String secureOtp = String.format("%06d", new Random().nextInt(900000) + 100000);
            order.setMeetupOtp(secureOtp);
            order.setMeetupOtpVerified(false);
            order.setMeetupLocation(req != null && req.getMeetupLocation() != null && !req.getMeetupLocation().isBlank()
                    ? req.getMeetupLocation()
                    : (listing.getLocality() != null ? listing.getLocality() : "Agreed Public Meeting Point"));
            order.setMeetupTime(req != null && req.getMeetupTime() != null
                    ? req.getMeetupTime()
                    : Instant.now().plus(Duration.ofHours(24)));
            order.setStatus(Order.OrderStatus.ORDER_CONFIRMED);

            Order saved = orderRepository.save(order);
            trackingEventRepository.save(new OrderTrackingEvent(saved, Order.OrderStatus.ORDER_CONFIRMED, "Offer Accepted & Meetup Scheduled", "In-person meetup confirmed at " + saved.getMeetupLocation(), Instant.now()));
            return saved;
        } else {
            order.setCourierPartner("Ekart Logistics");
            order.setTrackingNumber("EKRT202608" + String.format("%04d", new Random().nextInt(9000) + 1000) + "IN");
            order.setEstimatedDeliveryDate(Instant.now().plus(Duration.ofDays(2)));
            order.setStatus(Order.OrderStatus.SHIPPED);

            Order saved = orderRepository.save(order);
            Instant t0 = Instant.now().minus(Duration.ofHours(12));
            Instant t1 = t0.plus(Duration.ofHours(2));
            Instant t2 = t1.plus(Duration.ofHours(6));

            trackingEventRepository.save(new OrderTrackingEvent(saved, Order.OrderStatus.ORDER_CONFIRMED, "Offer Accepted", "Direct Sale offer agreed for Rs. " + agreedAmount, t0));
            trackingEventRepository.save(new OrderTrackingEvent(saved, Order.OrderStatus.SELLER_CONFIRMED, "Seller Confirmed", "Seller accepted & packed the item", t1));
            trackingEventRepository.save(new OrderTrackingEvent(saved, Order.OrderStatus.SHIPPED, "Shipped", "Handed over to Ekart Logistics", t2));
            return saved;
        }
    }

    /**
     * Verifies In-Person Meetup OTP entered by the buyer.
     * Completes handover, updates order to DELIVERED, and releases payment to seller.
     */
    @Transactional
    public OrderSummaryDto verifyMeetupOtp(UUID orderId, String inputOtp, UUID currentUserId) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> BidlyException.notFound("Order not found: " + orderId));

        if (order.getDeliveryType() != Order.DeliveryType.IN_PERSON_MEETUP) {
            throw BidlyException.badRequest("This order is not set for in-person meetup");
        }

        if (inputOtp == null || inputOtp.isBlank()) {
            throw BidlyException.badRequest("OTP code is required");
        }

        if (order.getMeetupOtp() == null || !order.getMeetupOtp().trim().equals(inputOtp.trim())) {
            throw BidlyException.badRequest("Invalid OTP code. Please check the code shown by the seller.");
        }

        order.setMeetupOtpVerified(true);
        order.setStatus(Order.OrderStatus.DELIVERED);
        order.setPaymentStatus(Order.PaymentStatus.RELEASED);
        order.setDeliveredAt(Instant.now());

        Order saved = orderRepository.save(order);

        // Credit seller funds in wallet
        walletService.topUpFunds(
                order.getSeller().getId(),
                order.getAmount(),
                "Direct sale payout for verified handover order #" + order.getOrderNumber()
        );

        trackingEventRepository.save(new OrderTrackingEvent(saved, Order.OrderStatus.DELIVERED, "Handover Completed", "In-person handover verified with OTP code", Instant.now()));

        return mapToSummaryDto(saved, currentUserId);
    }

    /**
     * Idempotent order creation when an auction ends and winner is determined.
     */
    @Transactional
    public Order createOrderForWinningBid(Listing listing, Bid winningBid) {
        Optional<Order> existing = orderRepository.findFirstByListingIdOrderByCreatedAtDesc(listing.getId());
        if (existing.isPresent()) {
            return existing.get();
        }

        String orderNum = "ORD-2026-" + String.format("%05d", new Random().nextInt(90000) + 10000);
        BigDecimal wonAmount = winningBid.getAmount();
        BigDecimal platformFee = wonAmount.multiply(BigDecimal.valueOf(0.02)).setScale(0, RoundingMode.HALF_UP);
        BigDecimal totalAmount = wonAmount.add(platformFee);

        Order order = new Order(
                orderNum,
                listing,
                winningBid.getBidder(),
                listing.getSeller(),
                winningBid,
                winningBid.getDeliveryAddress(),
                wonAmount,
                platformFee,
                totalAmount
        );

        order.setCourierPartner("Ekart Logistics");
        order.setTrackingNumber("EKRT202608" + String.format("%04d", new Random().nextInt(9000) + 1000) + "IN");
        order.setEstimatedDeliveryDate(Instant.now().plus(Duration.ofDays(2)));
        order.setStatus(Order.OrderStatus.SHIPPED); // advanced to realistic delivery demo state
        order.setPaymentStatus(Order.PaymentStatus.IN_ESCROW);

        Order savedOrder = orderRepository.save(order);

        // Convert reserved funds into Escrow Hold
        walletService.convertReservationToEscrow(winningBid.getBidder().getId(), wonAmount, savedOrder.getId());

        // Create realistic tracking timeline
        Instant t0 = Instant.now().minus(Duration.ofHours(24));
        Instant t1 = t0.plus(Duration.ofHours(2));
        Instant t2 = t1.plus(Duration.ofHours(18));
        Instant t3 = t2.plus(Duration.ofHours(4));

        trackingEventRepository.save(new OrderTrackingEvent(savedOrder, Order.OrderStatus.AUCTION_WON, "Auction Won", "You won the auction", t0));
        trackingEventRepository.save(new OrderTrackingEvent(savedOrder, Order.OrderStatus.SELLER_CONFIRMED, "Seller Confirmed", "Seller accepted the order", t1));
        trackingEventRepository.save(new OrderTrackingEvent(savedOrder, Order.OrderStatus.PACKED, "Packed", "Item packed and ready", t2));
        trackingEventRepository.save(new OrderTrackingEvent(savedOrder, Order.OrderStatus.SHIPPED, "Shipped", "Handed over to Ekart Logistics", t3));

        return savedOrder;
    }

    @Transactional(readOnly = true)
    public OrderSummaryDto getOrderDetails(UUID orderId, UUID currentUserId) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> BidlyException.notFound("Order not found: " + orderId));
        return mapToSummaryDto(order);
    }

    @Transactional
    public OrderSummaryDto getOrCreateOrderByListing(UUID listingId, UUID currentUserId) {
        Optional<Order> existing = orderRepository.findFirstByListingIdOrderByCreatedAtDesc(listingId);
        if (existing.isPresent()) {
            return mapToSummaryDto(existing.get());
        }
        throw BidlyException.notFound("No active order found for listing: " + listingId);
    }

    /**
     * Buyer confirms product receipt -> Releases escrow to seller!
     */
    @Transactional
    public OrderSummaryDto confirmDelivery(UUID orderId, UUID currentUserId) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> BidlyException.notFound("Order not found: " + orderId));

        if (!order.getBuyer().getId().equals(currentUserId)) {
            throw BidlyException.forbidden("Only the buyer can confirm delivery of this order");
        }

        if (order.getStatus() == Order.OrderStatus.DELIVERED) {
            return mapToSummaryDto(order);
        }

        order.setStatus(Order.OrderStatus.DELIVERED);
        order.setPaymentStatus(Order.PaymentStatus.RELEASED);
        order.setDeliveredAt(Instant.now());
        orderRepository.save(order);

        // Credit payment to seller
        walletService.topUpFunds(
                order.getSeller().getId(),
                order.getAmount(),
                "Escrow payout released for completed order #" + order.getOrderNumber()
        );

        trackingEventRepository.save(new OrderTrackingEvent(
                order,
                Order.OrderStatus.DELIVERED,
                "Delivered",
                "Product delivered and confirmed by buyer",
                Instant.now()
        ));

        return mapToSummaryDto(order);
    }

    public OrderSummaryDto mapToSummaryDto(Order o) {
        OrderSummaryDto dto = new OrderSummaryDto();
        dto.setId(o.getId());
        dto.setOrderNumber(o.getOrderNumber());
        dto.setListingId(o.getListing().getId());
        dto.setProductTitle(o.getListing().getTitle());
        dto.setProductCondition(o.getListing().getCondition() != null ? o.getListing().getCondition().name() : "LIKE_NEW");

        String primaryImg = (o.getListing().getMedia() != null && !o.getListing().getMedia().isEmpty())
                ? o.getListing().getMedia().get(0).getUrl() : null;
        dto.setPrimaryImageUrl(mediaService.generatePresignedGetUrl(primaryImg, Duration.ofHours(4)));

        dto.setWonAmount(o.getAmount());
        dto.setPlatformFee(o.getPlatformFee());
        dto.setTotalAmount(o.getTotalAmount());
        dto.setStatus(o.getStatus().name());
        dto.setPaymentStatus(o.getPaymentStatus().name());
        dto.setCourierPartner(o.getCourierPartner() != null ? o.getCourierPartner() : "Ekart Logistics");
        dto.setTrackingNumber(o.getTrackingNumber());
        dto.setEstimatedDeliveryDate(o.getEstimatedDeliveryDate());
        dto.setDeliveredAt(o.getDeliveredAt());

        dto.setBuyerId(o.getBuyer().getId());
        dto.setBuyerName(o.getBuyer().getName() != null ? o.getBuyer().getName() : "Verified Buyer");

        dto.setSellerId(o.getSeller().getId());
        dto.setSellerName(o.getSeller().getName() != null ? o.getSeller().getName() : "Arun Tech Deals");
        dto.setSellerRating(o.getListing().getRating() != null ? o.getListing().getRating() : 4.9);
        dto.setSellerSalesCount(312);

        if (o.getDeliveryAddress() != null) {
            dto.setDeliveryAddressFullName(o.getDeliveryAddress().getFullName());
            dto.setDeliveryAddressPhone(o.getDeliveryAddress().getPhone());
            dto.setDeliveryAddressLine(o.getDeliveryAddress().getAddressLine());
            dto.setDeliveryAddressCity(o.getDeliveryAddress().getCity());
            dto.setDeliveryAddressPincode(o.getDeliveryAddress().getPincode());
        } else {
            dto.setDeliveryAddressFullName(dto.getBuyerName());
            dto.setDeliveryAddressPhone("+91 98765 43210");
            dto.setDeliveryAddressLine("42, Anna Nagar 3rd Street");
            dto.setDeliveryAddressCity("Chennai");
            dto.setDeliveryAddressPincode("600040");
        }

        dto.setOrderSource(o.getOrderSource() != null ? o.getOrderSource().name() : "AUCTION");
        dto.setDeliveryType(o.getDeliveryType() != null ? o.getDeliveryType().name() : "COURIER");
        dto.setMeetupLocation(o.getMeetupLocation());
        dto.setMeetupTime(o.getMeetupTime());
        dto.setMeetupOtp(o.getMeetupOtp());
        dto.setMeetupOtpVerified(o.getMeetupOtpVerified() != null ? o.getMeetupOtpVerified() : false);
        if (o.getOffer() != null) {
            dto.setOfferId(o.getOffer().getId());
        }

        List<OrderTrackingEvent> events = trackingEventRepository.findByOrderIdOrderByEventTimeAsc(o.getId());
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("MMM dd, h:mm a").withZone(ZoneId.systemDefault());

        List<OrderTrackingEventDto> timeline = new ArrayList<>();
        for (OrderTrackingEvent e : events) {
            timeline.add(new OrderTrackingEventDto(
                    e.getId(),
                    e.getStatus().name(),
                    e.getTitle(),
                    e.getDescription(),
                    e.getEventTime(),
                    formatter.format(e.getEventTime()),
                    true
            ));
        }
        dto.setTrackingTimeline(timeline);

        return dto;
    }

    public OrderSummaryDto mapToSummaryDto(Order o, UUID currentUserId) {
        OrderSummaryDto dto = mapToSummaryDto(o);
        if (currentUserId != null) {
            dto.setSeller(currentUserId.equals(o.getSeller().getId()));
            dto.setBuyer(currentUserId.equals(o.getBuyer().getId()));
        }
        return dto;
    }
}
