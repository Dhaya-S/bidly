/// All named route paths used with GoRouter.
abstract class AppRoutes {
  // Auth
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/auth/phone';
  static const phoneEntry = '/auth/phone';
  static const otpVerify = '/auth/otp';

  // Post-Signup Onboarding Setup Flow
  static const setupIdentity = '/setup/identity';
  static const setupProcessing = '/setup/processing';
  static const setupLocation = '/setup/location';
  static const setupInterests = '/setup/interests';

  // Main shell
  static const home = '/home';
  static const categories = '/categories';
  static const profile = '/profile';
  static const community = '/community';
  static const exploreCommunities = '/community/explore';
  static const createCommunity = '/community/create';
  static const communitySuccess = '/community/success';
  static const communityPreview = '/community/preview';
  static const communityDetail = '/community/:id';

  // Listing & Sell Flow
  static const sell = '/sell';
  static const sellScope = '/sell/scope';
  static const sellType = '/sell/type';
  static const sellPreview = '/sell/preview';
  static const sellSuccess = '/sell/success';
  static const listingDetail = '/listing/:id';
  static const createListing = '/listing/create';
  static const editListing = '/listing/:id/edit';
  static const myListings = '/profile/listings';
  static const savedListings = '/profile/saved';

  // Category browse
  static const categoryListings = '/category/:id';

  // Search
  static const search = '/search';

  // Chat
  static const chatList = '/chats';
  static const chatConversation = '/chats/:roomId';
  static const offerChat = '/chat/offer/:listingId';

  // Auction Flow
  static const auctionBid = '/auction/:id/bid';
  static const auctionTracker = '/auction/:id/tracker';
  static const auctionWon = '/auction/:id/won';
  static const orderTrack = '/orders/:id/track';
  static const orderTrackByListing = '/orders/listing/:listingId/track';
  static const orderDeliveryConfirmation = '/orders/:id/delivery-confirmation';
  static const orderReview = '/orders/:id/review';

  // Settings & Profile Sub-flows
  static const settings = '/settings';
  static const personalInfo = '/profile/personal-info';
  static const privacySecurity = '/profile/privacy-security';
  static const helpSupport = '/profile/help-support';
  static const wishlist = '/profile/wishlist';
  static const boostPlans = '/profile/boost';
  static const sellerSubscription = '/seller-subscription';
  static const notifications = '/notifications';

  // Orders Flow
  static const orders = '/orders';
  static const productHistory = '/orders/:id/history';

  // Wallet Flow
  static const addMoney = '/wallet/add-money';
  static const moneyAddedSuccess = '/wallet/success';
}

/// App-wide string constants.
abstract class AppStrings {
  static const appName = 'Bidly';
  static const tagline = 'Buy & Sell Near You';
}
