package com.bidly;

import com.bidly.address.entity.DeliveryAddress;
import com.bidly.address.repository.DeliveryAddressRepository;
import com.bidly.auction.dto.AuctionWinnerDto;
import com.bidly.auction.dto.BidResponseDto;
import com.bidly.auction.dto.PlaceBidRequest;
import com.bidly.auction.entity.Bid;
import com.bidly.auction.repository.BidRepository;
import com.bidly.auction.service.AuctionService;
import com.bidly.chat.entity.ChatRoom;
import com.bidly.chat.repository.ChatMessageRepository;
import com.bidly.chat.repository.ChatRoomRepository;
import com.bidly.common.exception.BidlyException;
import com.bidly.listing.entity.Listing;
import com.bidly.listing.repository.ListingRepository;
import com.bidly.media.service.MediaService;
import com.bidly.notification.service.NotificationService;
import com.bidly.order.dto.CourierShipmentRequest;
import com.bidly.order.dto.OrderSummaryDto;
import com.bidly.order.dto.UpdateOrderAddressRequest;
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
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@org.mockito.junit.jupiter.MockitoSettings(strictness = org.mockito.quality.Strictness.LENIENT)
public class AuctionMoneyWinnerOrderIntegrationTest {

    @Mock private ListingRepository listingRepository;
    @Mock private BidRepository bidRepository;
    @Mock private UserRepository userRepository;
    @Mock private DeliveryAddressRepository addressRepository;
    @Mock private WalletService walletService;
    @Mock private SimpMessagingTemplate messagingTemplate;
    @Mock private MediaService mediaService;
    @Mock private OrderRepository orderRepository;
    @Mock private OrderTrackingEventRepository trackingEventRepository;
    @Mock private NotificationService notificationService;
    @Mock private ChatRoomRepository chatRoomRepository;
    @Mock private ChatMessageRepository chatMessageRepository;
    @Mock private com.bidly.review.repository.ReviewRepository reviewRepository;

    private AuctionService auctionService;
    private OrderService orderService;

    private User seller;
    private User buyerA;
    private User buyerB;
    private User stranger;
    private Listing auctionListing;
    private DeliveryAddress buyerAAddress;

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

        auctionService = new AuctionService(
                listingRepository,
                bidRepository,
                userRepository,
                addressRepository,
                walletService,
                mediaService,
                orderService,
                orderRepository,
                notificationService,
                chatRoomRepository,
                chatMessageRepository,
                reviewRepository,
                messagingTemplate
        );

        seller = new User();
        seller.setId(UUID.randomUUID());
        seller.setName("Seller Name");
        seller.setEmail("seller@example.com");
        seller.setPhone("9876543210");

        buyerA = new User();
        buyerA.setId(UUID.randomUUID());
        buyerA.setName("Buyer A");
        buyerA.setEmail("buyera@example.com");
        buyerA.setPhone("9123456780");

        buyerB = new User();
        buyerB.setId(UUID.randomUUID());
        buyerB.setName("Buyer B");
        buyerB.setEmail("buyerb@example.com");
        buyerB.setPhone("9123456781");

        stranger = new User();
        stranger.setId(UUID.randomUUID());
        stranger.setName("Random Stranger");
        stranger.setEmail("stranger@example.com");
        stranger.setPhone("9123456789");

        auctionListing = new Listing();
        auctionListing.setId(UUID.randomUUID());
        auctionListing.setTitle("iPhone 13 Pro 256GB");
        auctionListing.setSeller(seller);
        auctionListing.setSellingMethod(Listing.SellingMethod.AUCTION);
        auctionListing.setStatus(Listing.ListingStatus.ACTIVE);
        auctionListing.setStartingBid(BigDecimal.valueOf(40000.00));
        auctionListing.setCurrentBid(BigDecimal.valueOf(42500.00));
        auctionListing.setBidIncrement(BigDecimal.valueOf(500.00));
        auctionListing.setAuctionEndTime(Instant.now().plus(2, ChronoUnit.HOURS));

        buyerAAddress = new DeliveryAddress();
        buyerAAddress.setId(UUID.randomUUID());
        buyerAAddress.setUser(buyerA);
        buyerAAddress.setFullName("Buyer A");
        buyerAAddress.setPhone("9123456780");
        buyerAAddress.setAddressLine("42, Anna Nagar 3rd Street");
        buyerAAddress.setCity("Chennai");
        buyerAAddress.setPincode("600040");
    }

    @Test
    @DisplayName("Complete Auction Money & Order Lifecycle: Buyer A bids, Buyer B outbids, A increases bid, Auction ends, Order created, Address secured, Courier dispatched, Delivery confirmed once")
    void testAuctionMoneyWinnerOrderFullLifecycle() {
        // 1. SETUP: Mock repository fetches
        when(listingRepository.findByIdWithPessimisticLock(auctionListing.getId())).thenReturn(Optional.of(auctionListing));
        when(listingRepository.findById(auctionListing.getId())).thenReturn(Optional.of(auctionListing));
        when(userRepository.findById(buyerA.getId())).thenReturn(Optional.of(buyerA));
        when(userRepository.findById(buyerB.getId())).thenReturn(Optional.of(buyerB));
        when(addressRepository.findById(buyerAAddress.getId())).thenReturn(Optional.of(buyerAAddress));
        when(walletService.validateAvailableFunds(any(UUID.class), any(BigDecimal.class))).thenReturn(true);

        when(bidRepository.save(any(Bid.class))).thenAnswer(invocation -> {
            Bid b = invocation.getArgument(0);
            if (b.getId() == null) b.setId(UUID.randomUUID());
            return b;
        });

        // -------------------------------------------------------------
        // STEP 1: Buyer A places bid of ₹43,500
        // -------------------------------------------------------------
        PlaceBidRequest bidReqA = new PlaceBidRequest(BigDecimal.valueOf(43500.00), buyerAAddress.getId(), "client-bid-A-01");
        BidResponseDto respA = auctionService.placeBid(auctionListing.getId(), buyerA.getId(), bidReqA);

        assertNotNull(respA);
        assertEquals(BigDecimal.valueOf(43500.00), respA.getBidAmount());
        assertEquals("ACTIVE", respA.getStatus());
        verify(walletService, times(1)).reserveFunds(eq(buyerA.getId()), eq(BigDecimal.valueOf(43500.00)), eq(auctionListing.getId()));

        // Update listing state to reflect Buyer A's bid
        auctionListing.setCurrentBid(BigDecimal.valueOf(43500.00));
        Bid bidA1 = new Bid(auctionListing, buyerA, BigDecimal.valueOf(43500.00), buyerAAddress, "client-bid-A-01");
        bidA1.setId(respA.getBidId());
        bidA1.setStatus(Bid.BidStatus.ACTIVE);

        // -------------------------------------------------------------
        // STEP 2: Idempotent Bid Check - repeated clientBidId does NOT duplicate reservation
        // -------------------------------------------------------------
        when(bidRepository.findByClientBidId("client-bid-A-01")).thenReturn(Optional.of(bidA1));
        BidResponseDto respAIdempotent = auctionService.placeBid(auctionListing.getId(), buyerA.getId(), bidReqA);
        assertEquals(respA.getBidId(), respAIdempotent.getBidId());
        assertEquals("Bid already processed", respAIdempotent.getMessage());
        // verify reserveFunds was NOT called again for Buyer A
        verify(walletService, times(1)).reserveFunds(eq(buyerA.getId()), any(), any());

        // -------------------------------------------------------------
        // STEP 3: Buyer B outbids Buyer A with ₹45,000
        // -------------------------------------------------------------
        when(bidRepository.findByClientBidId("client-bid-B-01")).thenReturn(Optional.empty());
        when(bidRepository.findFirstByListingIdAndStatusOrderByAmountDescCreatedAtDesc(auctionListing.getId(), Bid.BidStatus.ACTIVE))
                .thenReturn(Optional.of(bidA1));
        when(bidRepository.findFirstByListingIdAndBidderIdAndStatusOrderByAmountDescCreatedAtDesc(auctionListing.getId(), buyerB.getId(), Bid.BidStatus.ACTIVE))
                .thenReturn(Optional.empty());

        PlaceBidRequest bidReqB = new PlaceBidRequest(BigDecimal.valueOf(45000.00), null, "client-bid-B-01");
        BidResponseDto respB = auctionService.placeBid(auctionListing.getId(), buyerB.getId(), bidReqB);

        assertNotNull(respB);
        assertEquals(BigDecimal.valueOf(45000.00), respB.getBidAmount());
        // Verify Buyer B's funds are reserved
        verify(walletService, times(1)).reserveFunds(eq(buyerB.getId()), eq(BigDecimal.valueOf(45000.00)), eq(auctionListing.getId()));
        // Verify Buyer A's funds are refunded/released upon being outbid
        verify(walletService, times(1)).releaseFunds(eq(buyerA.getId()), eq(BigDecimal.valueOf(43500.00)), eq(auctionListing.getId()), anyString());
        assertEquals(Bid.BidStatus.OUTBID, bidA1.getStatus());

        auctionListing.setCurrentBid(BigDecimal.valueOf(45000.00));
        Bid bidB1 = new Bid(auctionListing, buyerB, BigDecimal.valueOf(45000.00), null, "client-bid-B-01");
        bidB1.setId(respB.getBidId());
        bidB1.setStatus(Bid.BidStatus.ACTIVE);

        // -------------------------------------------------------------
        // STEP 4: Buyer A increases bid to ₹48,000 (Outbids B)
        // -------------------------------------------------------------
        when(bidRepository.findByClientBidId("client-bid-A-02")).thenReturn(Optional.empty());
        when(bidRepository.findFirstByListingIdAndStatusOrderByAmountDescCreatedAtDesc(auctionListing.getId(), Bid.BidStatus.ACTIVE))
                .thenReturn(Optional.of(bidB1));
        // Buyer A had no active bid since bidA1 was outbid
        when(bidRepository.findFirstByListingIdAndBidderIdAndStatusOrderByAmountDescCreatedAtDesc(auctionListing.getId(), buyerA.getId(), Bid.BidStatus.ACTIVE))
                .thenReturn(Optional.empty());

        PlaceBidRequest bidReqA2 = new PlaceBidRequest(BigDecimal.valueOf(48000.00), buyerAAddress.getId(), "client-bid-A-02");
        BidResponseDto respA2 = auctionService.placeBid(auctionListing.getId(), buyerA.getId(), bidReqA2);

        assertNotNull(respA2);
        assertEquals(BigDecimal.valueOf(48000.00), respA2.getBidAmount());
        // Verify Buyer A's new bid is reserved
        verify(walletService, times(1)).reserveFunds(eq(buyerA.getId()), eq(BigDecimal.valueOf(48000.00)), eq(auctionListing.getId()));
        // Verify Buyer B's funds are released
        verify(walletService, times(1)).releaseFunds(eq(buyerB.getId()), eq(BigDecimal.valueOf(45000.00)), eq(auctionListing.getId()), anyString());
        assertEquals(Bid.BidStatus.OUTBID, bidB1.getStatus());

        Bid winningBidA = new Bid(auctionListing, buyerA, BigDecimal.valueOf(48000.00), buyerAAddress, "client-bid-A-02");
        winningBidA.setId(respA2.getBidId());
        winningBidA.setStatus(Bid.BidStatus.ACTIVE);

        // -------------------------------------------------------------
        // STEP 5: AUCTION END - Seller ends auction -> Winner selected
        // -------------------------------------------------------------
        when(bidRepository.findFirstByListingIdAndStatusOrderByAmountDescCreatedAtDesc(auctionListing.getId(), Bid.BidStatus.ACTIVE))
                .thenReturn(Optional.of(winningBidA));
        when(bidRepository.findByListingIdAndStatus(auctionListing.getId(), Bid.BidStatus.ACTIVE))
                .thenReturn(List.of(winningBidA));

        Order createdOrder = new Order(
                "ORD-2026-08741",
                auctionListing,
                buyerA,
                seller,
                winningBidA,
                buyerAAddress,
                BigDecimal.valueOf(48000.00),
                BigDecimal.valueOf(960.00),
                BigDecimal.valueOf(48960.00)
        );
        createdOrder.setId(UUID.randomUUID());
        createdOrder.setStatus(Order.OrderStatus.AUCTION_WON);
        createdOrder.setPaymentStatus(Order.PaymentStatus.IN_ESCROW);

        when(orderRepository.save(any(Order.class))).thenReturn(createdOrder);

        AuctionWinnerDto winnerDto = auctionService.endAuctionManually(auctionListing.getId(), seller.getId());
        assertNotNull(winnerDto);
        assertEquals(buyerA.getId(), winnerDto.getWinnerId());
        assertEquals(BigDecimal.valueOf(48000.00), winnerDto.getWinningAmount());
        assertEquals(Listing.ListingStatus.SOLD, auctionListing.getStatus());
        // Verify winner's reservation is converted to Escrow
        verify(walletService, times(1)).convertReservationToEscrow(eq(buyerA.getId()), eq(BigDecimal.valueOf(48000.00)), eq(createdOrder.getId()));

        // -------------------------------------------------------------
        // STEP 6: DELIVERY ADDRESS SECURITY - Stranger cannot view order
        // -------------------------------------------------------------
        when(orderRepository.findById(createdOrder.getId())).thenReturn(Optional.of(createdOrder));
        assertThrows(BidlyException.class, () -> orderService.getOrderDetails(createdOrder.getId(), stranger.getId()),
                "Random authenticated user must not be able to view delivery address");

        // Buyer A and Seller CAN view order
        assertDoesNotThrow(() -> orderService.getOrderDetails(createdOrder.getId(), buyerA.getId()));
        assertDoesNotThrow(() -> orderService.getOrderDetails(createdOrder.getId(), seller.getId()));

        // -------------------------------------------------------------
        // STEP 7: Buyer A updates delivery address
        // -------------------------------------------------------------
        when(orderRepository.findByIdWithPessimisticLock(createdOrder.getId())).thenReturn(Optional.of(createdOrder));
        ChatRoom testRoom = new ChatRoom();
        testRoom.setId(UUID.randomUUID());
        testRoom.setListingId(auctionListing.getId());
        testRoom.setSellerId(seller.getId());
        testRoom.setBuyerId(buyerA.getId());
        when(chatRoomRepository.findByListingIdAndBuyerId(auctionListing.getId(), buyerA.getId()))
                .thenReturn(Optional.of(testRoom));

        UpdateOrderAddressRequest updateAddrReq = new UpdateOrderAddressRequest(
                null, "Buyer A Updated", "9123456780", "100 New Avenue", "Chennai", "600028"
        );
        when(addressRepository.save(any(DeliveryAddress.class))).thenAnswer(i -> i.getArgument(0));

        OrderSummaryDto updatedOrder = orderService.updateDeliveryAddress(createdOrder.getId(), buyerA.getId(), updateAddrReq);
        assertNotNull(updatedOrder);
        assertEquals("100 New Avenue", updatedOrder.getDeliveryAddressLine());
        verify(chatMessageRepository, times(1)).save(any()); // Delivery address card posted to chat

        // -------------------------------------------------------------
        // STEP 8: Seller creates Courier Shipment
        // -------------------------------------------------------------
        CourierShipmentRequest shipmentReq = new CourierShipmentRequest(
                "EKRT2005081234N", "Ekart Logistics", Instant.now().plus(3, ChronoUnit.DAYS)
        );
        OrderSummaryDto shippedOrder = orderService.createCourierShipment(createdOrder.getId(), seller.getId(), shipmentReq);
        assertEquals(Order.OrderStatus.SHIPPED.name(), shippedOrder.getStatus());
        assertEquals("Ekart Logistics", shippedOrder.getCourierPartner());
        assertEquals("EKRT2005081234N", shippedOrder.getTrackingNumber());

        // -------------------------------------------------------------
        // STEP 9: Buyer A confirms delivery -> Escrow released exactly once
        // -------------------------------------------------------------
        when(orderRepository.findByIdWithPessimisticLock(createdOrder.getId())).thenReturn(Optional.of(createdOrder));
        OrderSummaryDto deliveredOrder = orderService.confirmDelivery(createdOrder.getId(), buyerA.getId());

        assertEquals(Order.OrderStatus.DELIVERED.name(), deliveredOrder.getStatus());
        assertEquals("RELEASED", deliveredOrder.getPaymentStatus());
        verify(walletService, times(1)).topUpFunds(eq(seller.getId()), eq(BigDecimal.valueOf(48000.00)), anyString());

        // -------------------------------------------------------------
        // STEP 10: Idempotency Check - second call does NOT credit seller again
        // -------------------------------------------------------------
        OrderSummaryDto deliveredOrder2 = orderService.confirmDelivery(createdOrder.getId(), buyerA.getId());
        assertEquals(Order.OrderStatus.DELIVERED.name(), deliveredOrder2.getStatus());
        // Verify topUpFunds was NOT called a second time
        verify(walletService, times(1)).topUpFunds(eq(seller.getId()), any(), anyString());
    }

    @Test
    @DisplayName("5. Multi-Bidder Financial Test: A(10k) -> B(12k) -> C(15k) -> A(18k) -> Winner to Escrow & All Losers Refunded")
    void testMultiBidderSequenceAndLedgerConsistency() {
        User buyerC = new User();
        buyerC.setId(UUID.randomUUID());
        buyerC.setName("Buyer C");
        buyerC.setEmail("buyerc@example.com");
        buyerC.setPhone("9123456782");
        when(userRepository.findById(buyerA.getId())).thenReturn(Optional.of(buyerA));
        when(userRepository.findById(buyerB.getId())).thenReturn(Optional.of(buyerB));
        when(userRepository.findById(buyerC.getId())).thenReturn(Optional.of(buyerC));

        auctionListing.setStartingBid(BigDecimal.valueOf(8000.00));
        auctionListing.setCurrentBid(null);
        auctionListing.setBidIncrement(BigDecimal.valueOf(500.00));
        auctionListing.setAuctionEndTime(Instant.now().plus(2, ChronoUnit.HOURS));

        when(listingRepository.findById(auctionListing.getId())).thenReturn(Optional.of(auctionListing));
        when(listingRepository.findByIdWithPessimisticLock(auctionListing.getId())).thenReturn(Optional.of(auctionListing));
        when(walletService.validateAvailableFunds(any(), any())).thenReturn(true);

        // A bids ₹10,000
        when(bidRepository.findFirstByListingIdAndStatusOrderByAmountDescCreatedAtDesc(auctionListing.getId(), Bid.BidStatus.ACTIVE))
                .thenReturn(Optional.empty());
        when(bidRepository.findFirstByListingIdAndBidderIdAndStatusOrderByAmountDescCreatedAtDesc(auctionListing.getId(), buyerA.getId(), Bid.BidStatus.ACTIVE))
                .thenReturn(Optional.empty());
        when(bidRepository.save(any(Bid.class))).thenAnswer(i -> {
            Bid b = i.getArgument(0);
            b.setId(UUID.randomUUID());
            return b;
        });

        BidResponseDto respA1 = auctionService.placeBid(auctionListing.getId(), buyerA.getId(), new PlaceBidRequest(BigDecimal.valueOf(10000.00), null, "bid-A-10k"));
        assertEquals(BigDecimal.valueOf(10000.00), respA1.getBidAmount());
        verify(walletService, times(1)).reserveFunds(eq(buyerA.getId()), eq(BigDecimal.valueOf(10000.00)), eq(auctionListing.getId()));

        Bid bidA10 = new Bid(auctionListing, buyerA, BigDecimal.valueOf(10000.00), null, "bid-A-10k");
        bidA10.setId(respA1.getBidId());
        bidA10.setStatus(Bid.BidStatus.ACTIVE);

        // B bids ₹12,000 -> Outbids A
        when(bidRepository.findFirstByListingIdAndStatusOrderByAmountDescCreatedAtDesc(auctionListing.getId(), Bid.BidStatus.ACTIVE))
                .thenReturn(Optional.of(bidA10));
        when(bidRepository.findFirstByListingIdAndBidderIdAndStatusOrderByAmountDescCreatedAtDesc(auctionListing.getId(), buyerB.getId(), Bid.BidStatus.ACTIVE))
                .thenReturn(Optional.empty());

        BidResponseDto respB1 = auctionService.placeBid(auctionListing.getId(), buyerB.getId(), new PlaceBidRequest(BigDecimal.valueOf(12000.00), null, "bid-B-12k"));
        assertEquals(BigDecimal.valueOf(12000.00), respB1.getBidAmount());
        // B reserved 12k, A refunded 10k
        verify(walletService, times(1)).reserveFunds(eq(buyerB.getId()), eq(BigDecimal.valueOf(12000.00)), eq(auctionListing.getId()));
        verify(walletService, times(1)).releaseFunds(eq(buyerA.getId()), eq(BigDecimal.valueOf(10000.00)), eq(auctionListing.getId()), anyString());
        assertEquals(Bid.BidStatus.OUTBID, bidA10.getStatus());

        Bid bidB12 = new Bid(auctionListing, buyerB, BigDecimal.valueOf(12000.00), null, "bid-B-12k");
        bidB12.setId(respB1.getBidId());
        bidB12.setStatus(Bid.BidStatus.ACTIVE);

        // C bids ₹15,000 -> Outbids B
        when(bidRepository.findFirstByListingIdAndStatusOrderByAmountDescCreatedAtDesc(auctionListing.getId(), Bid.BidStatus.ACTIVE))
                .thenReturn(Optional.of(bidB12));
        when(bidRepository.findFirstByListingIdAndBidderIdAndStatusOrderByAmountDescCreatedAtDesc(auctionListing.getId(), buyerC.getId(), Bid.BidStatus.ACTIVE))
                .thenReturn(Optional.empty());

        BidResponseDto respC1 = auctionService.placeBid(auctionListing.getId(), buyerC.getId(), new PlaceBidRequest(BigDecimal.valueOf(15000.00), null, "bid-C-15k"));
        assertEquals(BigDecimal.valueOf(15000.00), respC1.getBidAmount());
        // C reserved 15k, B refunded 12k
        verify(walletService, times(1)).reserveFunds(eq(buyerC.getId()), eq(BigDecimal.valueOf(15000.00)), eq(auctionListing.getId()));
        verify(walletService, times(1)).releaseFunds(eq(buyerB.getId()), eq(BigDecimal.valueOf(12000.00)), eq(auctionListing.getId()), anyString());
        assertEquals(Bid.BidStatus.OUTBID, bidB12.getStatus());

        Bid bidC15 = new Bid(auctionListing, buyerC, BigDecimal.valueOf(15000.00), null, "bid-C-15k");
        bidC15.setId(respC1.getBidId());
        bidC15.setStatus(Bid.BidStatus.ACTIVE);

        // A bids ₹18,000 -> Outbids C
        when(bidRepository.findFirstByListingIdAndStatusOrderByAmountDescCreatedAtDesc(auctionListing.getId(), Bid.BidStatus.ACTIVE))
                .thenReturn(Optional.of(bidC15));
        when(bidRepository.findFirstByListingIdAndBidderIdAndStatusOrderByAmountDescCreatedAtDesc(auctionListing.getId(), buyerA.getId(), Bid.BidStatus.ACTIVE))
                .thenReturn(Optional.empty());

        BidResponseDto respA2 = auctionService.placeBid(auctionListing.getId(), buyerA.getId(), new PlaceBidRequest(BigDecimal.valueOf(18000.00), null, "bid-A-18k"));
        assertEquals(BigDecimal.valueOf(18000.00), respA2.getBidAmount());
        // A reserved 18k, C refunded 15k
        verify(walletService, times(1)).reserveFunds(eq(buyerA.getId()), eq(BigDecimal.valueOf(18000.00)), eq(auctionListing.getId()));
        verify(walletService, times(1)).releaseFunds(eq(buyerC.getId()), eq(BigDecimal.valueOf(15000.00)), eq(auctionListing.getId()), anyString());
        assertEquals(Bid.BidStatus.OUTBID, bidC15.getStatus());

        Bid bidA18 = new Bid(auctionListing, buyerA, BigDecimal.valueOf(18000.00), null, "bid-A-18k");
        bidA18.setId(respA2.getBidId());
        bidA18.setStatus(Bid.BidStatus.ACTIVE);

        // End auction -> Winner A is converted to Escrow
        when(bidRepository.findFirstByListingIdAndStatusOrderByAmountDescCreatedAtDesc(auctionListing.getId(), Bid.BidStatus.ACTIVE))
                .thenReturn(Optional.of(bidA18));
        when(bidRepository.findByListingIdAndStatus(auctionListing.getId(), Bid.BidStatus.ACTIVE))
                .thenReturn(List.of(bidA18));

        Order order = new Order("ORD-TEST", auctionListing, buyerA, seller, bidA18, null, BigDecimal.valueOf(18000.00), BigDecimal.valueOf(360.00), BigDecimal.valueOf(18360.00));
        order.setId(UUID.randomUUID());
        order.setStatus(Order.OrderStatus.AUCTION_WON);
        order.setPaymentStatus(Order.PaymentStatus.IN_ESCROW);
        when(orderRepository.save(any(Order.class))).thenReturn(order);

        AuctionWinnerDto winner = auctionService.endAuctionManually(auctionListing.getId(), seller.getId());
        assertEquals(buyerA.getId(), winner.getWinnerId());
        assertEquals(BigDecimal.valueOf(18000.00), winner.getWinningAmount());
        verify(walletService, times(1)).convertReservationToEscrow(eq(buyerA.getId()), eq(BigDecimal.valueOf(18000.00)), eq(order.getId()));
    }

    @Test
    @DisplayName("3. Countdown Test: Bids after auction expiry must be rejected by backend")
    void testCountdownExpirationRejectsBids() {
        auctionListing.setAuctionEndTime(Instant.now().minus(1, ChronoUnit.MINUTES));
        when(listingRepository.findByIdWithPessimisticLock(auctionListing.getId())).thenReturn(Optional.of(auctionListing));

        BidlyException ex = assertThrows(BidlyException.class, () ->
                auctionService.placeBid(auctionListing.getId(), buyerA.getId(), new PlaceBidRequest(BigDecimal.valueOf(50000.00), null, "expired-bid"))
        );
        assertTrue(ex.getMessage().contains("AUCTION_ENDED") || ex.getMessage().contains("expired"));
    }

    @Test
    @DisplayName("4 & 7 & 8. Authorization Tests: Non-seller ending, non-buyer confirming, stranger updating address")
    void testAuthorizationRestrictions() {
        // Non-seller cannot end auction
        when(listingRepository.findByIdWithPessimisticLock(auctionListing.getId())).thenReturn(Optional.of(auctionListing));
        assertThrows(BidlyException.class, () ->
                auctionService.endAuctionManually(auctionListing.getId(), buyerA.getId())
        );

        // Create mock order
        Order testOrder = new Order("ORD-AUTH", auctionListing, buyerA, seller, null, null, BigDecimal.valueOf(10000.00), BigDecimal.ZERO, BigDecimal.valueOf(10000.00));
        testOrder.setId(UUID.randomUUID());
        when(orderRepository.findByIdWithPessimisticLock(testOrder.getId())).thenReturn(Optional.of(testOrder));

        // Seller CANNOT confirm delivery (only buyer can)
        assertThrows(BidlyException.class, () ->
                orderService.confirmDelivery(testOrder.getId(), seller.getId())
        );

        // Stranger CANNOT confirm delivery
        assertThrows(BidlyException.class, () ->
                orderService.confirmDelivery(testOrder.getId(), stranger.getId())
        );

        // Stranger CANNOT update delivery address
        assertThrows(BidlyException.class, () ->
                orderService.updateDeliveryAddress(testOrder.getId(), stranger.getId(), new UpdateOrderAddressRequest(null, "Hacker", "12345", "Fake St", "City", "123456"))
        );
    }
}
