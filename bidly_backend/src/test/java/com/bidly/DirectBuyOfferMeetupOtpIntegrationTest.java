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
import com.bidly.notification.entity.Notification;
import com.bidly.notification.service.NotificationService;
import com.bidly.offer.dto.*;
import com.bidly.offer.entity.Offer;
import com.bidly.offer.repository.OfferRepository;
import com.bidly.offer.service.OfferService;
import com.bidly.order.dto.*;
import com.bidly.order.entity.Order;
import com.bidly.order.repository.OrderRepository;
import com.bidly.order.repository.OrderTrackingEventRepository;
import com.bidly.order.service.OrderService;
import com.bidly.review.dto.CreateReviewRequest;
import com.bidly.review.dto.ReviewDto;
import com.bidly.review.entity.Review;
import com.bidly.review.repository.ReviewRepository;
import com.bidly.review.service.ReviewService;
import com.bidly.user.entity.User;
import com.bidly.user.repository.UserRepository;
import com.bidly.wallet.service.WalletService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.messaging.simp.SimpMessagingTemplate;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class DirectBuyOfferMeetupOtpIntegrationTest {

    @Mock private OfferRepository offerRepository;
    @Mock private ListingRepository listingRepository;
    @Mock private UserRepository userRepository;
    @Mock private ChatRoomRepository chatRoomRepository;
    @Mock private ChatMessageRepository chatMessageRepository;
    @Mock private NotificationService notificationService;
    @Mock private SimpMessagingTemplate messagingTemplate;
    @Mock private OrderRepository orderRepository;
    @Mock private OrderTrackingEventRepository trackingEventRepository;
    @Mock private WalletService walletService;
    @Mock private MediaService mediaService;
    @Mock private ReviewRepository reviewRepository;
    @Mock private com.bidly.address.repository.DeliveryAddressRepository addressRepository;

    private OfferService offerService;
    private OrderService orderService;
    private ReviewService reviewService;

    private User buyer;
    private User seller;
    private Listing directListing;
    private ChatRoom chatRoom;

    @BeforeEach
    void setUp() {
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

        reviewService = new ReviewService(
                reviewRepository,
                orderRepository,
                userRepository,
                mediaService
        );

        buyer = new User();
        buyer.setId(UUID.randomUUID());
        buyer.setName("Arjun Kumar");
        buyer.setEmail("arjun@buyer.com");

        seller = new User();
        seller.setId(UUID.randomUUID());
        seller.setName("Tech Deals Chennai");
        seller.setEmail("techdeals@seller.com");

        Category electronics = new Category();
        electronics.setId(UUID.randomUUID());
        electronics.setName("Electronics");

        directListing = new Listing();
        directListing.setId(UUID.randomUUID());
        directListing.setTitle("Samsung Galaxy S23 Ultra");
        directListing.setSellingMethod(Listing.SellingMethod.DIRECT_BUY);
        directListing.setStatus(Listing.ListingStatus.ACTIVE);
        directListing.setPrice(new BigDecimal("52000.00"));
        directListing.setSeller(seller);
        directListing.setCategory(electronics);
        directListing.setLocality("Coimbatore");

        chatRoom = new ChatRoom();
        chatRoom.setId(UUID.randomUUID());
        chatRoom.setListingId(directListing.getId());
        chatRoom.setBuyerId(buyer.getId());
        chatRoom.setSellerId(seller.getId());
    }

    @Test
    @DisplayName("TEST 1 — Buyer submits offer: saves PENDING offer, notifies seller in real-time")
    void test1_buyerSubmitsOffer() {
        CreateOfferRequest req = new CreateOfferRequest();
        req.setListingId(directListing.getId());
        req.setAmount(new BigDecimal("50000.00"));
        req.setMessage("Can we meet tomorrow?");

        when(listingRepository.findById(directListing.getId())).thenReturn(Optional.of(directListing));
        when(userRepository.findById(buyer.getId())).thenReturn(Optional.of(buyer));
        when(chatRoomRepository.findByListingIdAndBuyerId(directListing.getId(), buyer.getId()))
                .thenReturn(Optional.of(chatRoom));
        when(chatMessageRepository.save(any(ChatMessage.class))).thenAnswer(i -> {
            ChatMessage m = i.getArgument(0);
            m.setId(UUID.randomUUID());
            return m;
        });

        when(offerRepository.save(any(Offer.class))).thenAnswer(invocation -> {
            Offer o = invocation.getArgument(0);
            o.setId(UUID.randomUUID());
            return o;
        });

        OfferDto result = offerService.createOffer(directListing.getId(), buyer.getId(), req);

        assertNotNull(result);
        assertEquals("PENDING", result.getStatus());
        assertEquals(50000.0, result.getAmount().doubleValue());
        assertEquals("Arjun Kumar", result.getBuyerName());
        assertEquals("Tech Deals Chennai", result.getSellerName());

        verify(notificationService).sendNotification(
                eq(seller),
                eq(Notification.NotificationType.NEW_OFFER),
                eq("New Offer Received"),
                contains("Arjun Kumar"),
                eq(directListing),
                any(Offer.class),
                isNull(),
                anyString(),
                anyString(),
                any(),
                anyString()
        );
    }

    @Test
    @DisplayName("TEST 2 — Seller rejects offer with reason: updates status to REJECTED, notifies buyer")
    void test2_sellerRejectsOffer() {
        Offer pendingOffer = new Offer(directListing, buyer, seller, new BigDecimal("40000.00"), "Offer");
        pendingOffer.setId(UUID.randomUUID());
        pendingOffer.setStatus(Offer.OfferStatus.PENDING);

        RejectOfferRequest rejectReq = new RejectOfferRequest();
        rejectReq.setReason("Price too low");
        rejectReq.setNote("Asking price is firm at 52k");

        when(offerRepository.findByIdWithPessimisticLock(pendingOffer.getId())).thenReturn(Optional.of(pendingOffer));
        when(userRepository.findById(seller.getId())).thenReturn(Optional.of(seller));
        when(offerRepository.save(any(Offer.class))).thenAnswer(i -> i.getArgument(0));
        when(chatRoomRepository.findByListingIdAndBuyerId(directListing.getId(), buyer.getId()))
                .thenReturn(Optional.of(chatRoom));
        when(chatMessageRepository.save(any(ChatMessage.class))).thenAnswer(i -> {
            ChatMessage m = i.getArgument(0);
            m.setId(UUID.randomUUID());
            return m;
        });

        OfferDto rejected = offerService.rejectOffer(pendingOffer.getId(), seller.getId(), rejectReq);

        assertNotNull(rejected);
        assertEquals("REJECTED", rejected.getStatus());
        assertEquals("Price too low", pendingOffer.getRejectionReason());

        verify(notificationService).sendNotification(
                eq(buyer),
                eq(Notification.NotificationType.OFFER_REJECTED),
                eq("Offer Declined"),
                anyString(),
                eq(directListing),
                eq(pendingOffer),
                isNull(),
                anyString(),
                anyString(),
                any(),
                anyString()
        );
    }

    @Test
    @DisplayName("TEST 3 — Seller accepts offer: creates Order in escrow, sets delivery to IN_PERSON_MEETUP")
    void test3_sellerAcceptsOffer() {
        Offer offer = new Offer(directListing, buyer, seller, new BigDecimal("50000.00"), "Offer");
        offer.setId(UUID.randomUUID());
        offer.setStatus(Offer.OfferStatus.PENDING);

        Order mockOrder = new Order();
        mockOrder.setId(UUID.randomUUID());
        mockOrder.setOrderNumber("ORD-1001");
        mockOrder.setListing(directListing);
        mockOrder.setBuyer(buyer);
        mockOrder.setSeller(seller);
        mockOrder.setAmount(new BigDecimal("50000.00"));
        mockOrder.setStatus(Order.OrderStatus.ORDER_CONFIRMED);
        mockOrder.setPaymentStatus(Order.PaymentStatus.IN_ESCROW);

        AcceptOfferRequest acceptReq = new AcceptOfferRequest();
        acceptReq.setDeliveryType("IN_PERSON_MEETUP");
        acceptReq.setMeetupLocation("T. Nagar, Chennai");

        when(offerRepository.findByIdWithPessimisticLock(offer.getId())).thenReturn(Optional.of(offer));
        when(listingRepository.findByIdWithPessimisticLock(directListing.getId())).thenReturn(Optional.of(directListing));
        when(userRepository.findById(seller.getId())).thenReturn(Optional.of(seller));
        when(offerRepository.save(any(Offer.class))).thenAnswer(i -> i.getArgument(0));
        when(orderRepository.save(any(Order.class))).thenReturn(mockOrder);
        when(offerRepository.findByListingIdAndStatus(directListing.getId(), Offer.OfferStatus.PENDING))
                .thenReturn(List.of(offer));
        when(chatRoomRepository.findByListingIdAndBuyerId(directListing.getId(), buyer.getId()))
                .thenReturn(Optional.of(chatRoom));
        when(chatMessageRepository.save(any(ChatMessage.class))).thenAnswer(i -> {
            ChatMessage m = i.getArgument(0);
            m.setId(UUID.randomUUID());
            return m;
        });

        OfferDto accepted = offerService.acceptOffer(offer.getId(), seller.getId(), acceptReq);

        assertNotNull(accepted);
        assertEquals("ACCEPTED", accepted.getStatus());
        assertEquals(mockOrder.getId(), accepted.getOrderId());

        verify(orderRepository).save(argThat(order ->
                order.getOrderSource() == Order.OrderSource.DIRECT_SALE &&
                order.getDeliveryType() == Order.DeliveryType.IN_PERSON_MEETUP &&
                order.getPaymentStatus() == Order.PaymentStatus.IN_ESCROW &&
                order.getMeetupOtp() != null &&
                order.getMeetupOtp().length() == 6
        ));

        verify(notificationService).sendNotification(
                eq(buyer),
                eq(Notification.NotificationType.OFFER_ACCEPTED),
                eq("Offer Accepted!"),
                contains("accepted your offer"),
                eq(directListing),
                eq(offer),
                any(Order.class),
                anyString(),
                anyString(),
                any(),
                anyString()
        );
    }

    @Test
    @DisplayName("TEST 4 — Seller schedules meetup: updates meetup time/location, generates 6-digit OTP, posts to chat")
    void test4_sellerSchedulesMeetup() {
        Order order = new Order();
        order.setId(UUID.randomUUID());
        order.setOrderNumber("ORD-1001");
        order.setListing(directListing);
        order.setBuyer(buyer);
        order.setSeller(seller);
        order.setDeliveryType(Order.DeliveryType.IN_PERSON_MEETUP);
        order.setStatus(Order.OrderStatus.ORDER_CONFIRMED);

        ScheduleMeetupRequest req = new ScheduleMeetupRequest();
        req.setLocation("T. Nagar, Chennai");
        req.setDateString("2026-06-23");
        req.setTimeString("10:00 AM");

        when(orderRepository.findByIdWithPessimisticLock(order.getId())).thenReturn(Optional.of(order));
        when(orderRepository.save(any(Order.class))).thenAnswer(i -> i.getArgument(0));
        when(chatRoomRepository.findByListingIdAndBuyerId(directListing.getId(), buyer.getId()))
                .thenReturn(Optional.of(chatRoom));
        when(chatMessageRepository.save(any(ChatMessage.class))).thenAnswer(i -> i.getArgument(0));

        OrderSummaryDto result = orderService.scheduleMeetup(order.getId(), seller.getId(), req);

        assertNotNull(result);
        assertEquals("T. Nagar, Chennai", order.getMeetupLocation());
        assertNotNull(order.getMeetupOtp());
        assertEquals(6, order.getMeetupOtp().length());
        assertFalse(order.getMeetupOtpVerified());

        verify(messagingTemplate).convertAndSend(
                eq("/topic/chats/" + chatRoom.getId()),
                (Object) anyMap()
        );

        verify(notificationService).sendNotification(
                eq(buyer),
                eq(Notification.NotificationType.MEETUP_SCHEDULED),
                eq("Meeting Scheduled"),
                anyString(),
                eq(directListing),
                isNull(),
                eq(order),
                eq("Show OTP"),
                anyString(),
                eq(order.getId()),
                anyString()
        );
    }

    @Test
    @DisplayName("TEST 5 — Buyer retrieves OTP: succeeds. Seller retrieving OTP throws 403 Forbidden")
    void test5_otpAccessControl() {
        Order order = new Order();
        order.setId(UUID.randomUUID());
        order.setOrderNumber("ORD-1002");
        order.setListing(directListing);
        order.setBuyer(buyer);
        order.setSeller(seller);
        order.setDeliveryType(Order.DeliveryType.IN_PERSON_MEETUP);
        order.setMeetupOtp("325725");
        order.setOtpExpiresAt(Instant.now().plus(Duration.ofHours(24)));
        order.setMeetupLocation("T. Nagar, Chennai");
        order.setMeetupTime(Instant.now().plus(Duration.ofHours(2)));

        when(orderRepository.findById(order.getId())).thenReturn(Optional.of(order));

        BuyerOtpDto buyerOtp = orderService.getBuyerOtp(order.getId(), buyer.getId());
        assertNotNull(buyerOtp);
        assertEquals("325725", buyerOtp.getOtp());
        assertEquals("Arjun Kumar", buyerOtp.getBuyerName());
        assertEquals("T. Nagar, Chennai", buyerOtp.getMeetupLocation());

        BidlyException ex = assertThrows(BidlyException.class, () ->
                orderService.getBuyerOtp(order.getId(), seller.getId())
        );
        assertEquals(HttpStatus.FORBIDDEN, ex.getStatus());
        assertTrue(ex.getMessage().contains("Only the buyer can retrieve the handover OTP"));
    }

    @Test
    @DisplayName("TEST 6 — Seller verifies OTP: wrong OTP increments attempt count; correct OTP sets verified")
    void test6_sellerVerifiesOtp() {
        Order order = new Order();
        order.setId(UUID.randomUUID());
        order.setOrderNumber("ORD-1003");
        order.setListing(directListing);
        order.setBuyer(buyer);
        order.setSeller(seller);
        order.setDeliveryType(Order.DeliveryType.IN_PERSON_MEETUP);
        order.setMeetupOtp("472856");
        order.setMeetupOtpVerified(false);
        order.setOtpAttemptCount(0);
        order.setOtpExpiresAt(Instant.now().plus(Duration.ofHours(24)));

        when(orderRepository.findByIdWithPessimisticLock(order.getId())).thenReturn(Optional.of(order));
        when(orderRepository.save(any(Order.class))).thenAnswer(i -> i.getArgument(0));

        BidlyException wrongOtpEx = assertThrows(BidlyException.class, () ->
                orderService.verifyMeetupOtp(order.getId(), "000000", seller.getId())
        );
        assertEquals(HttpStatus.BAD_REQUEST, wrongOtpEx.getStatus());
        assertEquals(1, order.getOtpAttemptCount());
        assertFalse(order.getMeetupOtpVerified());

        OrderSummaryDto verified = orderService.verifyMeetupOtp(order.getId(), "472856", seller.getId());
        assertNotNull(verified);
        assertTrue(order.getMeetupOtpVerified());

        verify(notificationService).sendNotification(
                eq(buyer),
                eq(Notification.NotificationType.OTP_VERIFIED),
                eq("OTP Verified"),
                contains("successfully verified"),
                eq(directListing),
                any(),
                eq(order),
                anyString(),
                anyString(),
                any(),
                isNull()
        );
    }

    @Test
    @DisplayName("TEST 7 — Seller marks sold: transitions order to DELIVERED, marks listing SOLD, credits wallet")
    void test7_sellerMarksSold() {
        Order order = new Order();
        order.setId(UUID.randomUUID());
        order.setOrderNumber("ORD-1004");
        order.setListing(directListing);
        order.setBuyer(buyer);
        order.setSeller(seller);
        order.setDeliveryType(Order.DeliveryType.IN_PERSON_MEETUP);
        order.setAmount(new BigDecimal("50000.00"));
        order.setPlatformFee(BigDecimal.ZERO);
        order.setTotalAmount(new BigDecimal("50000.00"));
        order.setMeetupOtpVerified(true);
        order.setStatus(Order.OrderStatus.ORDER_CONFIRMED);
        order.setPaymentStatus(Order.PaymentStatus.IN_ESCROW);
        order.setOrderSource(Order.OrderSource.DIRECT_SALE);

        when(orderRepository.findByIdWithPessimisticLock(order.getId())).thenReturn(Optional.of(order));
        when(listingRepository.findByIdWithPessimisticLock(directListing.getId())).thenReturn(Optional.of(directListing));
        when(listingRepository.save(any(Listing.class))).thenAnswer(i -> i.getArgument(0));
        when(orderRepository.save(any(Order.class))).thenAnswer(i -> i.getArgument(0));
        when(orderRepository.findById(order.getId())).thenReturn(Optional.of(order));
        when(chatRoomRepository.findByListingIdAndBuyerId(directListing.getId(), buyer.getId()))
                .thenReturn(Optional.of(chatRoom));

        SaleSummaryDto saleSummary = orderService.markSold(order.getId(), seller.getId());

        assertNotNull(saleSummary);
        assertEquals(Order.OrderStatus.DELIVERED, order.getStatus());
        assertEquals(Listing.ListingStatus.SOLD, directListing.getStatus());
        assertEquals(Order.PaymentStatus.RELEASED, order.getPaymentStatus());

        verify(walletService).topUpFunds(
                eq(seller.getId()),
                eq(new BigDecimal("50000.00")),
                contains("Direct sale payout")
        );

        verify(notificationService).sendNotification(
                eq(buyer),
                eq(Notification.NotificationType.ITEM_SOLD),
                eq("Product Handover Completed"),
                contains("marked sold"),
                eq(directListing),
                any(),
                eq(order),
                eq("Rate Seller"),
                contains("/review"),
                eq(order.getId()),
                isNull()
        );
    }

    @Test
    @DisplayName("TEST 8 — Buyer submits review & rating: saves review and updates seller feedback")
    void test8_buyerSubmitsReview() {
        Order completedOrder = new Order();
        completedOrder.setId(UUID.randomUUID());
        completedOrder.setOrderNumber("ORD-1005");
        completedOrder.setListing(directListing);
        completedOrder.setBuyer(buyer);
        completedOrder.setSeller(seller);
        completedOrder.setStatus(Order.OrderStatus.DELIVERED);

        CreateReviewRequest req = new CreateReviewRequest();
        req.setOrderId(completedOrder.getId());
        req.setRating(5);
        req.setComment("Phone in mint condition, handed over smoothly!");

        when(orderRepository.findById(completedOrder.getId())).thenReturn(Optional.of(completedOrder));
        when(reviewRepository.existsByOrderId(completedOrder.getId())).thenReturn(false);
        when(userRepository.findById(buyer.getId())).thenReturn(Optional.of(buyer));
        when(reviewRepository.save(any(Review.class))).thenAnswer(invocation -> {
            Review r = invocation.getArgument(0);
            r.setId(UUID.randomUUID());
            return r;
        });

        ReviewDto reviewDto = reviewService.createReview(buyer.getId(), req);

        assertNotNull(reviewDto);
        assertEquals(5, reviewDto.getRating());
        assertEquals("Phone in mint condition, handed over smoothly!", reviewDto.getComment());
        assertEquals("Arjun Kumar", reviewDto.getReviewerName());
    }
}
