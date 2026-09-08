package com.bidly.auction.service;

import com.bidly.address.entity.DeliveryAddress;
import com.bidly.address.repository.DeliveryAddressRepository;
import com.bidly.auction.entity.Bid;
import com.bidly.auction.repository.BidRepository;
import com.bidly.listing.entity.Listing;
import com.bidly.listing.repository.ListingRepository;
import com.bidly.order.entity.Order;
import com.bidly.order.service.OrderService;
import com.bidly.user.entity.User;
import com.bidly.user.repository.UserRepository;
import com.bidly.wallet.service.WalletService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Optional;

@Service
public class AuctionSeedService {

    private static final Logger log = LoggerFactory.getLogger(AuctionSeedService.class);

    private final ListingRepository listingRepository;
    private final BidRepository bidRepository;
    private final UserRepository userRepository;
    private final DeliveryAddressRepository addressRepository;
    private final WalletService walletService;
    private final OrderService orderService;

    public AuctionSeedService(
            ListingRepository listingRepository,
            BidRepository bidRepository,
            UserRepository userRepository,
            DeliveryAddressRepository addressRepository,
            WalletService walletService,
            OrderService orderService) {
        this.listingRepository = listingRepository;
        this.bidRepository = bidRepository;
        this.userRepository = userRepository;
        this.addressRepository = addressRepository;
        this.walletService = walletService;
        this.orderService = orderService;
    }

    @EventListener(ApplicationReadyEvent.class)
    @Transactional
    public void seedInitialAuctionData() {
        try {
            List<User> users = userRepository.findAll();
            if (users.isEmpty()) return;

            // 1. Ensure each existing user has a wallet entity initialized
            for (User u : users) {
                walletService.getOrCreateWalletEntity(u.getId());
            }

            // 2. Ensure existing auction listings have valid end times without inserting mock bids
            List<Listing> auctionListings = listingRepository.findAll().stream()
                    .filter(l -> l.getSellingMethod() == Listing.SellingMethod.AUCTION)
                    .toList();

            for (Listing listing : auctionListings) {
                boolean changed = false;
                if (listing.getAuctionEndTime() == null) {
                    listing.setAuctionEndTime(Instant.now().plus(Duration.ofHours(24)));
                    listing.setStatus(Listing.ListingStatus.ACTIVE);
                    changed = true;
                }

                int realBids = (int) bidRepository.countByListingIdAndStatusNot(listing.getId(), Bid.BidStatus.WITHDRAWN);
                if (realBids != listing.getBidsCount()) {
                    listing.setBidsCount(realBids);
                    if (realBids == 0 && listing.getStartingBid() != null) {
                        listing.setCurrentBid(listing.getStartingBid());
                    }
                    changed = true;
                }

                if (changed) {
                    listingRepository.save(listing);
                }
            }
        } catch (Exception e) {
            log.warn("Auction initialization skipped: {}", e.getMessage());
        }
    }
}
