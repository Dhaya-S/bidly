package com.bidly.review.service;

import com.bidly.common.exception.BidlyException;
import com.bidly.media.service.MediaService;
import com.bidly.order.entity.Order;
import com.bidly.order.repository.OrderRepository;
import com.bidly.review.dto.CreateReviewRequest;
import com.bidly.review.dto.ReviewDto;
import com.bidly.review.entity.Review;
import com.bidly.review.entity.ReviewPhoto;
import com.bidly.review.repository.ReviewRepository;
import com.bidly.user.entity.User;
import com.bidly.user.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.util.Collections;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class ReviewService {

    private final ReviewRepository reviewRepository;
    private final OrderRepository orderRepository;
    private final UserRepository userRepository;
    private final MediaService mediaService;
    private final com.bidly.notification.service.NotificationService notificationService;

    public ReviewService(
            ReviewRepository reviewRepository,
            OrderRepository orderRepository,
            UserRepository userRepository,
            MediaService mediaService,
            com.bidly.notification.service.NotificationService notificationService) {
        this.reviewRepository = reviewRepository;
        this.orderRepository = orderRepository;
        this.userRepository = userRepository;
        this.mediaService = mediaService;
        this.notificationService = notificationService;
    }

    @Transactional
    public ReviewDto createReview(UUID currentUserId, CreateReviewRequest req) {
        Order order = orderRepository.findById(req.getOrderId())
                .or(() -> orderRepository.findFirstByListingIdOrderByCreatedAtDesc(req.getOrderId()))
                .or(() -> orderRepository.findByOfferId(req.getOrderId()))
                .orElseThrow(() -> BidlyException.notFound("Order not found: " + req.getOrderId()));

        if (!order.getBuyer().getId().equals(currentUserId)) {
            throw BidlyException.forbidden("Only the buyer of this order can leave a review");
        }

        if (order.getStatus() != Order.OrderStatus.DELIVERED) {
            order.setStatus(Order.OrderStatus.DELIVERED);
            order.setDeliveredAt(java.time.Instant.now());
            orderRepository.save(order);
        }

        if (reviewRepository.existsByOrderId(order.getId())) {
            return reviewRepository.findByOrderId(order.getId()).map(this::mapToDto).orElse(null);
        }

        User reviewer = userRepository.findById(currentUserId)
                .orElseThrow(() -> BidlyException.notFound("User not found: " + currentUserId));

        Review review = new Review(
                order,
                reviewer,
                order.getSeller(),
                order.getListing(),
                req.getRating(),
                req.getComment() != null ? req.getComment().trim() : ""
        );

        if (req.getPhotoUrls() != null && !req.getPhotoUrls().isEmpty()) {
            for (String photo : req.getPhotoUrls()) {
                review.getPhotos().add(new ReviewPhoto(review, photo));
            }
        }

        Review saved = reviewRepository.save(review);

        // Notify Seller of new review
        notificationService.sendNotification(
                order.getSeller(),
                com.bidly.notification.entity.Notification.NotificationType.REVIEW_RECEIVED,
                "New Review Received",
                reviewer.getName() + " left a " + req.getRating() + "-star review for " + order.getListing().getTitle(),
                order.getListing(),
                order.getOffer(),
                order,
                "View Review",
                "/chat/offer/" + order.getListing().getId(),
                order.getId(),
                null
        );

        return mapToDto(saved);
    }

    @Transactional(readOnly = true)
    public ReviewDto getReviewByOrderId(UUID orderId) {
        return reviewRepository.findByOrderId(orderId)
                .or(() -> orderRepository.findFirstByListingIdOrderByCreatedAtDesc(orderId)
                        .flatMap(o -> reviewRepository.findByOrderId(o.getId())))
                .or(() -> orderRepository.findByOfferId(orderId)
                        .flatMap(o -> reviewRepository.findByOrderId(o.getId())))
                .map(this::mapToDto)
                .orElse(null);
    }

    @Transactional(readOnly = true)
    public List<ReviewDto> getSellerReviews(UUID sellerId) {
        return reviewRepository.findBySellerIdOrderByCreatedAtDesc(sellerId).stream()
                .map(this::mapToDto)
                .collect(Collectors.toList());
    }

    public ReviewDto mapToDto(Review r) {
        ReviewDto dto = new ReviewDto();
        dto.setId(r.getId());
        dto.setOrderId(r.getOrder().getId());
        dto.setReviewerId(r.getReviewer().getId());
        dto.setReviewerName(r.getReviewer().getName() != null ? r.getReviewer().getName() : "Verified Buyer");
        dto.setReviewerAvatar(r.getReviewer().getAvatarUrl());
        dto.setSellerId(r.getSeller().getId());
        dto.setSellerName(r.getSeller().getName() != null ? r.getSeller().getName() : "Verified Seller");
        dto.setRating(r.getRating());
        dto.setComment(r.getComment());
        dto.setCreatedAt(r.getCreatedAt());

        if (r.getPhotos() != null && !r.getPhotos().isEmpty()) {
            dto.setPhotoUrls(r.getPhotos().stream()
                    .map(p -> {
                        String presigned = mediaService.generatePresignedGetUrl(p.getPhotoUrl(), Duration.ofHours(4));
                        return presigned != null ? presigned : p.getPhotoUrl();
                    })
                    .collect(Collectors.toList()));
        } else {
            dto.setPhotoUrls(Collections.emptyList());
        }

        return dto;
    }
}
