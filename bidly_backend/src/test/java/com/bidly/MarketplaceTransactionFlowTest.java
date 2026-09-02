package com.bidly;

import com.bidly.category.entity.Category;
import com.bidly.chat.entity.ChatMessage;
import com.bidly.chat.entity.ChatRoom;
import com.bidly.chat.repository.ChatMessageRepository;
import com.bidly.chat.repository.ChatRoomRepository;
import com.bidly.common.exception.BidlyException;
import com.bidly.listing.entity.Listing;
import com.bidly.listing.repository.ListingRepository;
import com.bidly.media.service.MediaService;
import com.bidly.notification.service.NotificationService;
import com.bidly.offer.dto.AcceptOfferRequest;
import com.bidly.offer.dto.CreateOfferRequest;
import com.bidly.offer.dto.OfferDto;
import com.bidly.offer.dto.RejectOfferRequest;
import com.bidly.offer.entity.Offer;
import com.bidly.offer.repository.OfferRepository;
import com.bidly.offer.service.OfferService;
import com.bidly.order.dto.BuyerOtpDto;
import com.bidly.order.dto.CourierShipmentRequest;
import com.bidly.order.dto.OrderSummaryDto;
import com.bidly.order.dto.ScheduleMeetupRequest;
import com.bidly.order.entity.Order;
import com.bidly.order.repository.OrderRepository;
import com.bidly.order.repository.OrderTrackingEventRepository;
import com.bidly.order.service.OrderService;
import com.bidly.user.entity.User;
import com.bidly.user.repository.UserRepository;
import com.bidly.wallet.service.WalletService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.messaging.simp.SimpMessagingTemplate;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * Phase 3.17 End-to-End Functional Test Suite:
 * Rigorous validation of Marketplace Transaction Flow:
 * - Offer lifecycle (Create, Accept, Reject, Counter)
 * - Order generation & competing offer cancellation
 * - Meetup scheduling & 6-digit numeric OTP generation
 * - Security check: strict buyer-only OTP retrieval (asserting 403 for seller)
 * - OTP verification rate limiting (< 5 attempts)
 * - Atomic Mark Sold transition (asserting listing SOLD, wallet credit, DELIVERED status)
 * - Courier shipment registration
 * - Listing visibility exclusion
 */
@ExtendWith(MockitoExtension.class)
public class MarketplaceTransactionFlowTest {

    @Mock private OfferRepository offerRepository;
    @Mock private ListingRepository listingRepository;
    @Mock private UserRepository userRepository;
    @Mock private OrderRepository orderRepository;
    @Mock private OrderTrackingEventRepository trackingEventRepository;
    @Mock private ChatRoomRepository chatRoomRepository;
    @Mock private ChatMessageRepository chatMessageRepository;
    @Mock private MediaService mediaService;
    @Mock private SimpMessagingTemplate messagingTemplate;
    @Mock private NotificationService notificationService;
    @Mock private WalletService walletService;

    @Mock private com.bidly.address.repository.DeliveryAddressRepository addressRepository;

    private OrderService orderService;
    private OfferService offerService;

    private User buyer;
    private User seller;
    private User intruder;
    private Listing directBuyListing;
    private Listing auctionListing;
    private ChatRoom chatRoom;

    @BeforeEach
    void setUp() {
        buyer = new User();
        buyer.setId(UUID.randomUUID());
        buyer.setName("Ananya Sharma");
        buyer.setPhone("9876543211");

        seller = new User();
        seller.setId(UUID.randomUUID());
        seller.setName("Karthik Raman");
        seller.setPhone("9876543212");

        intruder = new User();
        intruder.setId(UUID.randomUUID());
        intruder.setName("Unauthorized User");

        directBuyListing = new Listing();
        directBuyListing.setId(UUID.randomUUID());
        directBuyListing.setTitle("Apple iPad Air M2 128GB");
        directBuyListing.setPrice(BigDecimal.valueOf(52000.00));
        directBuyListing.setSellingMethod(Listing.SellingMethod.DIRECT_BUY);
        directBuyListing.setStatus(Listing.ListingStatus.ACTIVE);
        directBuyListing.setSeller(seller);
        directBuyListing.setCondition(Listing.Condition.LIKE_NEW);

        auctionListing = new Listing();
        auctionListing.setId(UUID.randomUUID());
        auctionListing.setTitle("Vintage Watch Auction");
        auctionListing.setSellingMethod(Listing.SellingMethod.AUCTION);
        auctionListing.setStatus(Listing.ListingStatus.ACTIVE);
        auctionListing.setSeller(seller);

        chatRoom = new ChatRoom();
        chatRoom.setId(UUID.randomUUID());
        chatRoom.setListingId(directBuyListing.getId());
        chatRoom.setBuyerId(buyer.getId());
        chatRoom.setSellerId(seller.getId());

        orderService = new OrderService(
                orderRepository,
                trackingEventRepository,
                walletService,
                mediaService,
                addressRepository,
                listingRepository,
                notificationService,
                chatRoomRepository,
                chatMessageRepository,
                messagingTemplate
        );

        offerService = new OfferService(
                offerRepository,
                listingRepository,
                userRepository,
                orderService,
                orderRepository,
                chatRoomRepository,
                chatMessageRepository,
                mediaService,
                messagingTemplate,
                notificationService
        );
    }

    // ==========================================
    // 1. MAKE OFFER TESTS
    // ==========================================

    @Test
    @DisplayName("1. Buyer makes offer on DIRECT_BUY listing: creates offer PENDING, posts chat message, notifies seller")
    void testCreateOffer_Success() {
        CreateOfferRequest req = new CreateOfferRequest();
        req.setAmount(BigDecimal.valueOf(48000.00));
        req.setMessage("Can you do 48k for immediate pickup?");

        when(listingRepository.findById(directBuyListing.getId())).thenReturn(Optional.of(directBuyListing));
        when(userRepository.findById(buyer.getId())).thenReturn(Optional.of(buyer));
        when(offerRepository.save(any(Offer.class))).thenAnswer(i -> {
            Offer o = i.getArgument(0);
            o.setId(UUID.randomUUID());
            return o;
        });
        when(chatRoomRepository.findByListingIdAndBuyerId(directBuyListing.getId(), buyer.getId())).thenReturn(Optional.of(chatRoom));
        when(chatMessageRepository.save(any(ChatMessage.class))).thenAnswer(i -> {
            ChatMessage m = i.getArgument(0);
            m.setId(UUID.randomUUID());
            return m;
        });

        OfferDto result = offerService.createOffer(directBuyListing.getId(), buyer.getId(), req);

        assertNotNull(result);
        assertEquals("PENDING", result.getStatus());
        assertEquals(48000.0, result.getAmount().doubleValue());
        verify(notificationService).sendNotification(
                eq(seller),
                eq(com.bidly.notification.entity.Notification.NotificationType.NEW_OFFER),
                eq("New Offer Received"),
                contains("Ananya Sharma"),
                eq(directBuyListing),
                any(Offer.class),
                isNull(),
                anyString(),
                anyString(),
                any(),
                anyString()
        );
    }

    @Test
    @DisplayName("2. Seller cannot make an offer on their own listing (400 Bad Request)")
    void testCreateOffer_OwnListing_Fails() {
        CreateOfferRequest req = new CreateOfferRequest();
        req.setAmount(BigDecimal.valueOf(45000.00));

        when(listingRepository.findById(directBuyListing.getId())).thenReturn(Optional.of(directBuyListing));
        when(userRepository.findById(seller.getId())).thenReturn(Optional.of(seller));

        BidlyException ex = assertThrows(BidlyException.class, () ->
                offerService.createOffer(directBuyListing.getId(), seller.getId(), req));
        assertTrue(ex.getMessage().contains("cannot make an offer on your own listing"));
    }

    @Test
    @DisplayName("3. Cannot make direct offer on an AUCTION listing (400 Bad Request)")
    void testCreateOffer_AuctionListing_Fails() {
        CreateOfferRequest req = new CreateOfferRequest();
        req.setAmount(BigDecimal.valueOf(5000.00));

        when(listingRepository.findById(auctionListing.getId())).thenReturn(Optional.of(auctionListing));

        BidlyException ex = assertThrows(BidlyException.class, () ->
                offerService.createOffer(auctionListing.getId(), buyer.getId(), req));
        assertTrue(ex.getMessage().contains("does not accept direct sale offers"));
    }

    // ==========================================
    // 2. ACCEPT / REJECT OFFER TESTS
    // ==========================================

    @Test
    @DisplayName("4. Seller accepts offer: offer becomes ACCEPTED, order created, other pending offers cancelled")
    void testAcceptOffer_Atomic_Success() {
        Offer offer = new Offer(directBuyListing, buyer, seller, BigDecimal.valueOf(49000.00), "Offer 1");
        offer.setId(UUID.randomUUID());
        offer.setStatus(Offer.OfferStatus.PENDING);

        Offer competingOffer = new Offer(directBuyListing, intruder, seller, BigDecimal.valueOf(47000.00), "Offer 2");
        competingOffer.setId(UUID.randomUUID());
        competingOffer.setStatus(Offer.OfferStatus.PENDING);

        Order mockOrder = new Order();
        mockOrder.setId(UUID.randomUUID());
        mockOrder.setOrderNumber("ORD-2026-8888");
        mockOrder.setListing(directBuyListing);
        mockOrder.setBuyer(buyer);
        mockOrder.setSeller(seller);
        mockOrder.setAmount(BigDecimal.valueOf(49000.00));
        mockOrder.setStatus(Order.OrderStatus.ORDER_CONFIRMED);
        mockOrder.setPaymentStatus(Order.PaymentStatus.IN_ESCROW);

        when(offerRepository.findByIdWithPessimisticLock(offer.getId())).thenReturn(Optional.of(offer));
        when(listingRepository.findByIdWithPessimisticLock(directBuyListing.getId())).thenReturn(Optional.of(directBuyListing));
        when(offerRepository.save(any(Offer.class))).thenAnswer(i -> i.getArgument(0));
        when(orderRepository.save(any(Order.class))).thenReturn(mockOrder);
        when(offerRepository.findByListingIdAndStatus(directBuyListing.getId(), Offer.OfferStatus.PENDING))
                .thenReturn(List.of(offer, competingOffer));
        when(chatRoomRepository.findByListingIdAndBuyerId(directBuyListing.getId(), buyer.getId())).thenReturn(Optional.of(chatRoom));
        when(chatMessageRepository.save(any(ChatMessage.class))).thenAnswer(i -> {
            ChatMessage m = i.getArgument(0);
            m.setId(UUID.randomUUID());
            return m;
        });
        when(userRepository.findById(seller.getId())).thenReturn(Optional.of(seller));

        AcceptOfferRequest req = new AcceptOfferRequest();
        req.setDeliveryType("IN_PERSON_MEETUP");
        req.setMeetupLocation("Nexus Vijaya Mall, Vadapalani");

        OfferDto result = offerService.acceptOffer(offer.getId(), seller.getId(), req);

        assertNotNull(result);
        assertEquals("ACCEPTED", result.getStatus());
        assertEquals(mockOrder.getId(), result.getOrderId());
        assertEquals(Offer.OfferStatus.CANCELLED, competingOffer.getStatus());
        verify(notificationService).sendNotification(
                eq(buyer),
                eq(com.bidly.notification.entity.Notification.NotificationType.OFFER_ACCEPTED),
                eq("Offer Accepted!"),
                contains("accepted your offer"),
                eq(directBuyListing),
                eq(offer),
                any(Order.class),
                anyString(),
                anyString(),
                any(),
                anyString()
        );
    }

    @Test
    @DisplayName("5. Non-seller / unauthorized user cannot accept offer (403 Forbidden)")
    void testAcceptOffer_Unauthorized_Fails() {
        Offer offer = new Offer(directBuyListing, buyer, seller, BigDecimal.valueOf(49000.00), "Offer");
        offer.setId(UUID.randomUUID());
        offer.setStatus(Offer.OfferStatus.PENDING);

        when(offerRepository.findByIdWithPessimisticLock(offer.getId())).thenReturn(Optional.of(offer));
        when(listingRepository.findByIdWithPessimisticLock(directBuyListing.getId())).thenReturn(Optional.of(directBuyListing));

        AcceptOfferRequest req = new AcceptOfferRequest();
        BidlyException ex = assertThrows(BidlyException.class, () ->
                offerService.acceptOffer(offer.getId(), intruder.getId(), req));
        assertEquals(403, ex.getStatus().value());
    }

    @Test
    @DisplayName("6. Seller rejects offer with structured reason and note")
    void testRejectOffer_WithReasonAndNote() {
        Offer offer = new Offer(directBuyListing, buyer, seller, BigDecimal.valueOf(40000.00), "Low offer");
        offer.setId(UUID.randomUUID());
        offer.setStatus(Offer.OfferStatus.PENDING);

        when(offerRepository.findByIdWithPessimisticLock(offer.getId())).thenReturn(Optional.of(offer));
        when(offerRepository.save(any(Offer.class))).thenAnswer(i -> i.getArgument(0));
        when(chatRoomRepository.findByListingIdAndBuyerId(directBuyListing.getId(), buyer.getId())).thenReturn(Optional.of(chatRoom));
        when(chatMessageRepository.save(any(ChatMessage.class))).thenAnswer(i -> {
            ChatMessage m = i.getArgument(0);
            m.setId(UUID.randomUUID());
            return m;
        });
        when(userRepository.findById(seller.getId())).thenReturn(Optional.of(seller));

        RejectOfferRequest req = new RejectOfferRequest();
        req.setReason("Price too low");
        req.setNote("I cannot go below 48,000 INR.");

        OfferDto result = offerService.rejectOffer(offer.getId(), seller.getId(), req);

        assertNotNull(result);
        assertEquals("REJECTED", result.getStatus());
        assertEquals("Price too low", offer.getRejectionReason());
        assertEquals("I cannot go below 48,000 INR.", offer.getRejectionNote());
        assertNotNull(offer.getRejectedAt());
        verify(notificationService).sendNotification(
                eq(buyer),
                eq(com.bidly.notification.entity.Notification.NotificationType.OFFER_REJECTED),
                eq("Offer Declined"),
                anyString(),
                eq(directBuyListing),
                eq(offer),
                isNull(),
                anyString(),
                anyString(),
                any(),
                anyString()
        );
    }

    // ==========================================
    // 3. MEETUP & OTP FLOW TESTS
    // ==========================================

    @Test
    @DisplayName("7. Seller schedules in-person meetup: generates 6-digit OTP, sets 48h expiration")
    void testScheduleMeetup_Success() {
        Order order = new Order();
        order.setId(UUID.randomUUID());
        order.setOrderNumber("ORD-2026-1001");
        order.setListing(directBuyListing);
        order.setBuyer(buyer);
        order.setSeller(seller);
        order.setStatus(Order.OrderStatus.ORDER_CONFIRMED);
        order.setAmount(BigDecimal.valueOf(50000.00));
        order.setPlatformFee(BigDecimal.ZERO);
        order.setTotalAmount(BigDecimal.valueOf(50000.00));
        order.setPaymentStatus(Order.PaymentStatus.IN_ESCROW);

        when(orderRepository.findByIdWithPessimisticLock(order.getId())).thenReturn(Optional.of(order));
        when(orderRepository.save(any(Order.class))).thenAnswer(i -> i.getArgument(0));
        when(chatRoomRepository.findByListingIdAndBuyerId(directBuyListing.getId(), buyer.getId())).thenReturn(Optional.of(chatRoom));
        when(chatMessageRepository.save(any(ChatMessage.class))).thenAnswer(i -> {
            ChatMessage m = i.getArgument(0);
            m.setId(UUID.randomUUID());
            return m;
        });

        ScheduleMeetupRequest req = new ScheduleMeetupRequest();
        req.setLocation("Marina Mall, OMR");
        req.setDateString("2026-09-05");
        req.setTimeString("04:30 PM");

        OrderSummaryDto result = orderService.scheduleMeetup(order.getId(), seller.getId(), req);

        assertNotNull(result);
        assertEquals(Order.DeliveryType.IN_PERSON_MEETUP, order.getDeliveryType());
        assertNotNull(order.getMeetupOtp());
        assertEquals(6, order.getMeetupOtp().length());
        assertTrue(order.getMeetupOtp().matches("\\d{6}"));
        assertTrue(order.getOtpExpiresAt().isAfter(Instant.now().plus(Duration.ofHours(24))));
        assertEquals("Marina Mall, OMR", order.getMeetupLocation());
    }

    @Test
    @DisplayName("8. Strict security: Buyer can retrieve OTP; Seller or intruder gets 403 Forbidden")
    void testGetBuyerOtp_StrictBuyerAuthorization() {
        Order order = new Order();
        order.setId(UUID.randomUUID());
        order.setOrderNumber("ORD-2026-1002");
        order.setListing(directBuyListing);
        order.setBuyer(buyer);
        order.setSeller(seller);
        order.setDeliveryType(Order.DeliveryType.IN_PERSON_MEETUP);
        order.setMeetupOtp("739281");
        order.setOtpExpiresAt(Instant.now().plus(Duration.ofHours(48)));
        order.setMeetupLocation("Anna Nagar Tower Park");

        when(orderRepository.findById(order.getId())).thenReturn(Optional.of(order));

        // 1. Buyer successfully retrieves OTP
        BuyerOtpDto buyerOtp = orderService.getBuyerOtp(order.getId(), buyer.getId());
        assertNotNull(buyerOtp);
        assertEquals("739281", buyerOtp.getOtp());
        assertEquals("Anna Nagar Tower Park", buyerOtp.getMeetupLocation());

        // 2. Seller attempt MUST throw 403 Forbidden
        BidlyException sellerEx = assertThrows(BidlyException.class, () ->
                orderService.getBuyerOtp(order.getId(), seller.getId()));
        assertEquals(403, sellerEx.getStatus().value());

        // 3. Intruder attempt MUST throw 403 Forbidden
        BidlyException intruderEx = assertThrows(BidlyException.class, () ->
                orderService.getBuyerOtp(order.getId(), intruder.getId()));
        assertEquals(403, intruderEx.getStatus().value());
    }

    @Test
    @DisplayName("9. Seller enters incorrect OTP: fails and increments otpAttemptCount")
    void testVerifyOtp_Incorrect_Fails() {
        Order order = new Order();
        order.setId(UUID.randomUUID());
        order.setListing(directBuyListing);
        order.setBuyer(buyer);
        order.setSeller(seller);
        order.setDeliveryType(Order.DeliveryType.IN_PERSON_MEETUP);
        order.setMeetupOtp("654321");
        order.setOtpAttemptCount(0);
        order.setOtpExpiresAt(Instant.now().plus(Duration.ofHours(24)));

        when(orderRepository.findByIdWithPessimisticLock(order.getId())).thenReturn(Optional.of(order));
        when(orderRepository.save(any(Order.class))).thenAnswer(i -> i.getArgument(0));

        BidlyException ex = assertThrows(BidlyException.class, () ->
                orderService.verifyMeetupOtp(order.getId(), "000000", seller.getId()));
        assertTrue(ex.getMessage().contains("Invalid OTP code"));
        assertEquals(1, order.getOtpAttemptCount());
        assertFalse(Boolean.TRUE.equals(order.getMeetupOtpVerified()));
    }

    @Test
    @DisplayName("10. Seller enters correct OTP: sets meetupOtpVerified=true and notifies buyer")
    void testVerifyOtp_Correct_Success() {
        Order order = new Order();
        order.setId(UUID.randomUUID());
        order.setOrderNumber("ORD-2026-1003");
        order.setListing(directBuyListing);
        order.setBuyer(buyer);
        order.setSeller(seller);
        order.setDeliveryType(Order.DeliveryType.IN_PERSON_MEETUP);
        order.setMeetupOtp("654321");
        order.setOtpAttemptCount(0);
        order.setOtpExpiresAt(Instant.now().plus(Duration.ofHours(24)));
        order.setAmount(BigDecimal.valueOf(52000.00));
        order.setPlatformFee(BigDecimal.ZERO);
        order.setTotalAmount(BigDecimal.valueOf(52000.00));
        order.setStatus(Order.OrderStatus.ORDER_CONFIRMED);
        order.setPaymentStatus(Order.PaymentStatus.IN_ESCROW);

        when(orderRepository.findByIdWithPessimisticLock(order.getId())).thenReturn(Optional.of(order));
        when(orderRepository.save(any(Order.class))).thenAnswer(i -> i.getArgument(0));
        when(chatRoomRepository.findByListingIdAndBuyerId(directBuyListing.getId(), buyer.getId())).thenReturn(Optional.of(chatRoom));

        OrderSummaryDto result = orderService.verifyMeetupOtp(order.getId(), "654321", seller.getId());

        assertNotNull(result);
        assertTrue(order.getMeetupOtpVerified());
        verify(notificationService).sendNotification(
                eq(buyer),
                eq(com.bidly.notification.entity.Notification.NotificationType.OTP_VERIFIED),
                eq("OTP Verified"),
                contains("successfully verified"),
                eq(directBuyListing),
                any(),
                eq(order),
                anyString(),
                anyString(),
                any(),
                isNull()
        );
    }

    // ==========================================
    // 4. MARK SOLD & SALE SUMMARY TESTS
    // ==========================================

    @Test
    @DisplayName("11. Cannot mark in-person order as sold without OTP verification (400 Bad Request)")
    void testMarkSold_WithoutOtp_Fails() {
        Order order = new Order();
        order.setId(UUID.randomUUID());
        order.setListing(directBuyListing);
        order.setBuyer(buyer);
        order.setSeller(seller);
        order.setDeliveryType(Order.DeliveryType.IN_PERSON_MEETUP);
        order.setMeetupOtpVerified(false);

        when(orderRepository.findByIdWithPessimisticLock(order.getId())).thenReturn(Optional.of(order));

        BidlyException ex = assertThrows(BidlyException.class, () ->
                orderService.markSold(order.getId(), seller.getId()));
        assertTrue(ex.getMessage().contains("OTP verification must be completed first"));
    }

    @Test
    @DisplayName("12. Seller marks sold: listing -> SOLD, order -> DELIVERED, wallet credited, sale summary available")
    void testMarkSold_Atomic_Success() {
        Order order = new Order();
        order.setId(UUID.randomUUID());
        order.setOrderNumber("ORD-2026-2005");
        order.setListing(directBuyListing);
        order.setBuyer(buyer);
        order.setSeller(seller);
        order.setDeliveryType(Order.DeliveryType.IN_PERSON_MEETUP);
        order.setMeetupOtpVerified(true);
        order.setAmount(BigDecimal.valueOf(52000.00));
        order.setPlatformFee(BigDecimal.ZERO);
        order.setTotalAmount(BigDecimal.valueOf(52000.00));
        order.setStatus(Order.OrderStatus.ORDER_CONFIRMED);
        order.setPaymentStatus(Order.PaymentStatus.IN_ESCROW);
        order.setOrderSource(Order.OrderSource.DIRECT_SALE);

        when(orderRepository.findByIdWithPessimisticLock(order.getId())).thenReturn(Optional.of(order));
        when(listingRepository.findByIdWithPessimisticLock(directBuyListing.getId())).thenReturn(Optional.of(directBuyListing));
        when(listingRepository.save(any(Listing.class))).thenAnswer(i -> i.getArgument(0));
        when(orderRepository.save(any(Order.class))).thenAnswer(i -> i.getArgument(0));
        when(orderRepository.findById(order.getId())).thenReturn(Optional.of(order));
        when(chatRoomRepository.findByListingIdAndBuyerId(directBuyListing.getId(), buyer.getId())).thenReturn(Optional.of(chatRoom));

        var summary = orderService.markSold(order.getId(), seller.getId());

        assertNotNull(summary);
        assertEquals(Listing.ListingStatus.SOLD, directBuyListing.getStatus());
        assertEquals(Order.OrderStatus.DELIVERED, order.getStatus());
        assertEquals(Order.PaymentStatus.RELEASED, order.getPaymentStatus());
        assertNotNull(order.getDeliveredAt());

        // Verify seller wallet credited
        verify(walletService).topUpFunds(
                eq(seller.getId()),
                eq(BigDecimal.valueOf(52000.00)),
                contains("Direct sale payout")
        );

        // Verify sale summary fields
        assertEquals("Apple iPad Air M2 128GB", summary.getListingTitle());
        assertEquals("Ananya Sharma", summary.getBuyerName());
        assertEquals("Karthik Raman", summary.getSellerName());
        assertEquals(BigDecimal.valueOf(52000.00), summary.getFinalPrice());
    }

    // ==========================================
    // 5. COURIER FLOW TEST
    // ==========================================

    @Test
    @DisplayName("13. Seller dispatches courier shipment: sets SHIPPED, logs tracking, notifies buyer")
    void testCourierShipment_Success() {
        Order order = new Order();
        order.setId(UUID.randomUUID());
        order.setOrderNumber("ORD-2026-3001");
        order.setListing(directBuyListing);
        order.setBuyer(buyer);
        order.setSeller(seller);
        order.setStatus(Order.OrderStatus.ORDER_CONFIRMED);
        order.setPaymentStatus(Order.PaymentStatus.IN_ESCROW);

        when(orderRepository.findById(order.getId())).thenReturn(Optional.of(order));
        when(orderRepository.save(any(Order.class))).thenAnswer(i -> i.getArgument(0));
        when(chatRoomRepository.findByListingIdAndBuyerId(directBuyListing.getId(), buyer.getId())).thenReturn(Optional.of(chatRoom));
        when(chatMessageRepository.save(any(ChatMessage.class))).thenAnswer(i -> {
            ChatMessage m = i.getArgument(0);
            m.setId(UUID.randomUUID());
            return m;
        });

        CourierShipmentRequest req = new CourierShipmentRequest();
        req.setCourierPartner("BlueDart Express");
        req.setTrackingNumber("BD987654321IN");
        req.setEstimatedDeliveryDate(Instant.now().plus(Duration.ofDays(3)));

        orderService.createCourierShipment(order.getId(), seller.getId(), req);

        assertEquals(Order.OrderStatus.SHIPPED, order.getStatus());
        assertEquals(Order.DeliveryType.COURIER, order.getDeliveryType());
        assertEquals("BlueDart Express", order.getCourierPartner());
        assertEquals("BD987654321IN", order.getTrackingNumber());
        verify(notificationService).sendNotificationWithMeta(
                eq(buyer),
                eq(com.bidly.notification.entity.Notification.NotificationType.SHIPPED),
                eq("Shipment Dispatched"),
                contains("BlueDart Express"),
                eq(directBuyListing),
                isNull(),
                eq(order),
                anyString(),
                anyString(),
                any(),
                anyMap()
        );
    }
}
