class OfferModel {
  bool? error;
  List<OffersWithProducts>? offersWithProducts;

  OfferModel({this.error, this.offersWithProducts});

  OfferModel.fromJson(Map<String, dynamic> json) {
    error = json['error'];
    if (json['offers_with_products'] != null) {
      offersWithProducts = <OffersWithProducts>[];
      json['offers_with_products'].forEach((v) {
        offersWithProducts!.add(new OffersWithProducts.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['error'] = this.error;
    if (this.offersWithProducts != null) {
      data['offers_with_products'] =
          this.offersWithProducts!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class OffersWithProducts {
  Offer? offer;
  List<Products>? products;

  OffersWithProducts({this.offer, this.products});

  OffersWithProducts.fromJson(Map<String, dynamic> json) {
    offer = json['offer'] != null ? new Offer.fromJson(json['offer']) : null;
    if (json['products'] != null) {
      products = <Products>[];
      json['products'].forEach((v) {
        products!.add(new Products.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.offer != null) {
      data['offer'] = this.offer!.toJson();
    }
    if (this.products != null) {
      data['products'] = this.products!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Offer {
  String? id;
  String? type;
  String? typeId;
  String? image;
  String? gifUrl;
  String? dateAdded;
  String? link;

  Offer(
      {this.id,
      this.type,
      this.typeId,
      this.image,
      this.gifUrl,
      this.dateAdded,
      this.link});

  Offer.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    type = json['type'];
    typeId = json['type_id'];
    image = json['image'];
    gifUrl = json['gif_url'];
    dateAdded = json['date_added'];
    link = json['link'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['type'] = this.type;
    data['type_id'] = this.typeId;
    data['image'] = this.image;
    data['gif_url'] = this.gifUrl;
    data['date_added'] = this.dateAdded;
    data['link'] = this.link;
    return data;
  }
}

class Products {
  String? total;
  String? sales;
  String? stockType;
  String? isPricesInclusiveTax;
  String? type;
  String? attrValueIds;
  String? sellerRating;
  String? sellerSlug;
  String? sellerNoOfRatings;
  String? sellerProfile;
  String? storeName;
  String? storeDescription;
  String? openCloseStatus;
  String? sellerId;
  dynamic? sellerName;
  String? id;
  String? stock;
  String? name;
  String? categoryId;
  String? shortDescription;
  String? slug;
  String? description;
  String? hsnCode;
  dynamic? totalAllowedQuantity;
  String? deliverableType;
  dynamic? deliverableZipcodes;
  String? minimumOrderQuantity;
  String? quantityStepSize;
  String? codAllowed;
  String? rowOrder;
  String? rating;
  String? noOfRatings;
  String? image;
  String? isReturnable;
  String? isCancelable;
  String? cancelableTill;
  String? indicator;
  List<dynamic>? otherImages;
  String? videoType;
  String? video;
  List<String>? tags;
  String? warrantyPeriod;
  String? guaranteePeriod;
  String? madeIn;
  String? availability;
  String? categoryName;
  String? taxPercentage;
  List<dynamic>? reviewImages;
  List<dynamic>? attributes;
  List<Variants>? variants;
  MinMaxPrice? minMaxPrice;
  dynamic? deliverableZipcodesIds;
  bool? isDeliverable;
  bool? isPurchased;
  String? isFavorite;
  String? imageMd;
  String? imageSm;
  List<String>? otherImagesMd;
  List<String>? otherImagesSm;
  List<dynamic>? variantAttributes;
  String? link;

  Products(
      {this.total,
      this.sales,
      this.stockType,
      this.isPricesInclusiveTax,
      this.type,
      this.attrValueIds,
      this.sellerRating,
      this.sellerSlug,
      this.sellerNoOfRatings,
      this.sellerProfile,
      this.storeName,
      this.storeDescription,
      this.openCloseStatus,
      this.sellerId,
      this.sellerName,
      this.id,
      this.stock,
      this.name,
      this.categoryId,
      this.shortDescription,
      this.slug,
      this.description,
      this.hsnCode,
      this.totalAllowedQuantity,
      this.deliverableType,
      this.deliverableZipcodes,
      this.minimumOrderQuantity,
      this.quantityStepSize,
      this.codAllowed,
      this.rowOrder,
      this.rating,
      this.noOfRatings,
      this.image,
      this.isReturnable,
      this.isCancelable,
      this.cancelableTill,
      this.indicator,
      this.otherImages,
      this.videoType,
      this.video,
      this.tags,
      this.warrantyPeriod,
      this.guaranteePeriod,
      this.madeIn,
      this.availability,
      this.categoryName,
      this.taxPercentage,
      this.reviewImages,
      this.attributes,
      this.variants,
      this.minMaxPrice,
      this.deliverableZipcodesIds,
      this.isDeliverable,
      this.isPurchased,
      this.isFavorite,
      this.imageMd,
      this.imageSm,
      this.otherImagesMd,
      this.otherImagesSm,
      this.variantAttributes,
      this.link});

  Products.fromJson(Map<String, dynamic> json) {
    total = json['total'];
    sales = json['sales'];
    stockType = json['stock_type'];
    isPricesInclusiveTax = json['is_prices_inclusive_tax'];
    type = json['type'];
    attrValueIds = json['attr_value_ids'];
    sellerRating = json['seller_rating'];
    sellerSlug = json['seller_slug'];
    sellerNoOfRatings = json['seller_no_of_ratings'];
    sellerProfile = json['seller_profile'];
    storeName = json['store_name'];
    storeDescription = json['store_description'];
    openCloseStatus = json['open_close_status'];
    sellerId = json['seller_id'];
    sellerName = json['seller_name'];
    id = json['id'];
    stock = json['stock'];
    name = json['name'];
    categoryId = json['category_id'];
    shortDescription = json['short_description'];
    slug = json['slug'];
    description = json['description'];
    hsnCode = json['hsn_code'];
    totalAllowedQuantity = json['total_allowed_quantity'];
    deliverableType = json['deliverable_type'];
    deliverableZipcodes = json['deliverable_zipcodes'];
    minimumOrderQuantity = json['minimum_order_quantity'];
    quantityStepSize = json['quantity_step_size'];
    codAllowed = json['cod_allowed'];
    rowOrder = json['row_order'];
    rating = json['rating'];
    noOfRatings = json['no_of_ratings'];
    image = json['image'];
    isReturnable = json['is_returnable'];
    isCancelable = json['is_cancelable'];
    cancelableTill = json['cancelable_till'];
    indicator = json['indicator'];
    otherImages = json['other_images'].cast<String>();
    videoType = json['video_type'];
    video = json['video'];
    tags = json['tags'] != null ? List<String>.from(json['tags']) : null;
    // if (json['tags'] != null) {
    //   tags = <Null>[];
    //   json['tags'].forEach((v) {
    //     tags!.add(new Null.fromJson(v));
    //   });
    // }
    warrantyPeriod = json['warranty_period'];
    guaranteePeriod = json['guarantee_period'];
    madeIn = json['made_in'];
    availability = json['availability'];
    categoryName = json['category_name'];
    taxPercentage = json['tax_percentage'];
    reviewImages = json['review_images'] != null
        ? List<String>.from(json['review_images'])
        : null;
    attributes = json['attributes'] != null
        ? List<dynamic>.from(json['attributes'])
        : null;
    if (json['variants'] != null) {
      variants = <Variants>[];
      json['variants'].forEach((v) {
        variants!.add(new Variants.fromJson(v));
      });
    }
    minMaxPrice = json['min_max_price'] != null
        ? new MinMaxPrice.fromJson(json['min_max_price'])
        : null;
    deliverableZipcodesIds = json['deliverable_zipcodes_ids'];
    isDeliverable = json['is_deliverable'];
    isPurchased = json['is_purchased'];
    isFavorite = json['is_favorite'];
    imageMd = json['image_md'];
    imageSm = json['image_sm'];
    otherImagesMd = json['other_images_md'].cast<String>();
    otherImagesSm = json['other_images_sm'].cast<String>();
    if (json['variant_attributes'] != null) {
      variantAttributes = json['variant_attributes'] != null
          ? List<dynamic>.from(json['variant_attributes'])
          : null;
    }
    link = json['link'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['total'] = this.total;
    data['sales'] = this.sales;
    data['stock_type'] = this.stockType;
    data['is_prices_inclusive_tax'] = this.isPricesInclusiveTax;
    data['type'] = this.type;
    data['attr_value_ids'] = this.attrValueIds;
    data['seller_rating'] = this.sellerRating;
    data['seller_slug'] = this.sellerSlug;
    data['seller_no_of_ratings'] = this.sellerNoOfRatings;
    data['seller_profile'] = this.sellerProfile;
    data['store_name'] = this.storeName;
    data['store_description'] = this.storeDescription;
    data['open_close_status'] = this.openCloseStatus;
    data['seller_id'] = this.sellerId;
    data['seller_name'] = this.sellerName;
    data['id'] = this.id;
    data['stock'] = this.stock;
    data['name'] = this.name;
    data['category_id'] = this.categoryId;
    data['short_description'] = this.shortDescription;
    data['slug'] = this.slug;
    data['description'] = this.description;
    data['hsn_code'] = this.hsnCode;
    data['total_allowed_quantity'] = this.totalAllowedQuantity;
    data['deliverable_type'] = this.deliverableType;
    data['deliverable_zipcodes'] = this.deliverableZipcodes;
    data['minimum_order_quantity'] = this.minimumOrderQuantity;
    data['quantity_step_size'] = this.quantityStepSize;
    data['cod_allowed'] = this.codAllowed;
    data['row_order'] = this.rowOrder;
    data['rating'] = this.rating;
    data['no_of_ratings'] = this.noOfRatings;
    data['image'] = this.image;
    data['is_returnable'] = this.isReturnable;
    data['is_cancelable'] = this.isCancelable;
    data['cancelable_till'] = this.cancelableTill;
    data['indicator'] = this.indicator;
    data['other_images'] = this.otherImages;
    data['video_type'] = this.videoType;
    data['video'] = this.video;
    if (tags != null) data['tags'] = tags;
    data['warranty_period'] = this.warrantyPeriod;
    data['guarantee_period'] = this.guaranteePeriod;
    data['made_in'] = this.madeIn;
    data['availability'] = this.availability;
    data['category_name'] = this.categoryName;
    data['tax_percentage'] = this.taxPercentage;
    if (this.reviewImages != null) {
      data['review_images'] =
          this.reviewImages!.map((v) => v.toJson()).toList();
    }
    if (this.attributes != null) {
      data['attributes'] = this.attributes!.map((v) => v.toJson()).toList();
    }
    if (this.variants != null) {
      data['variants'] = this.variants!.map((v) => v.toJson()).toList();
    }
    if (this.minMaxPrice != null) {
      data['min_max_price'] = this.minMaxPrice!.toJson();
    }
    data['deliverable_zipcodes_ids'] = this.deliverableZipcodesIds;
    data['is_deliverable'] = this.isDeliverable;
    data['is_purchased'] = this.isPurchased;
    data['is_favorite'] = this.isFavorite;
    data['image_md'] = this.imageMd;
    data['image_sm'] = this.imageSm;
    data['other_images_md'] = this.otherImagesMd;
    data['other_images_sm'] = this.otherImagesSm;
    if (this.variantAttributes != null) {
      data['variant_attributes'] =
          this.variantAttributes!.map((v) => v.toJson()).toList();
    }
    data['link'] = this.link;
    return data;
  }
}

class Variants {
  String? id;
  String? productId;
  String? attributeValueIds;
  String? attributeSet;
  String? price;
  String? specialPrice;
  String? sku;
  String? stock;
  List<dynamic>? images;
  String? availability;
  String? status;
  String? dateAdded;
  String? variantIds;
  String? attrName;
  String? variantValues;
  String? swatcheType;
  String? swatcheValue;
  List<dynamic>? imagesMd;
  List<dynamic>? imagesSm;
  String? cartCount;

  Variants(
      {this.id,
      this.productId,
      this.attributeValueIds,
      this.attributeSet,
      this.price,
      this.specialPrice,
      this.sku,
      this.stock,
      this.images,
      this.availability,
      this.status,
      this.dateAdded,
      this.variantIds,
      this.attrName,
      this.variantValues,
      this.swatcheType,
      this.swatcheValue,
      this.imagesMd,
      this.imagesSm,
      this.cartCount});

  Variants.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    productId = json['product_id'];
    attributeValueIds = json['attribute_value_ids'];
    attributeSet = json['attribute_set'];
    price = json['price'];
    specialPrice = json['special_price'];
    sku = json['sku'];
    stock = json['stock'];
    images = json['images'] != null ? List<String>.from(json['images']) : null;
    availability = json['availability'];
    status = json['status'];
    dateAdded = json['date_added'];
    variantIds = json['variant_ids'];
    attrName = json['attr_name'];
    variantValues = json['variant_values'];
    swatcheType = json['swatche_type'];
    swatcheValue = json['swatche_value'];
    imagesMd =
        json['images_md'] != null ? List<String>.from(json['images_md']) : null;
    imagesSm =
        json['images_sm'] != null ? List<String>.from(json['images_sm']) : null;
    cartCount = json['cart_count'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['product_id'] = this.productId;
    data['attribute_value_ids'] = this.attributeValueIds;
    data['attribute_set'] = this.attributeSet;
    data['price'] = this.price;
    data['special_price'] = this.specialPrice;
    data['sku'] = this.sku;
    data['stock'] = this.stock;
    if (this.images != null) {
      data['images'] = this.images!.map((v) => v.toJson()).toList();
    }
    data['availability'] = this.availability;
    data['status'] = this.status;
    data['date_added'] = this.dateAdded;
    data['variant_ids'] = this.variantIds;
    data['attr_name'] = this.attrName;
    data['variant_values'] = this.variantValues;
    data['swatche_type'] = this.swatcheType;
    data['swatche_value'] = this.swatcheValue;
    if (this.imagesMd != null) {
      data['images_md'] = this.imagesMd!.map((v) => v.toJson()).toList();
    }
    if (this.imagesSm != null) {
      data['images_sm'] = this.imagesSm!.map((v) => v.toJson()).toList();
    }
    data['cart_count'] = this.cartCount;
    return data;
  }
}

class MinMaxPrice {
  int? minPrice;
  int? maxPrice;
  int? specialPrice;
  int? maxSpecialPrice;
  int? discountInPercentage;

  MinMaxPrice(
      {this.minPrice,
      this.maxPrice,
      this.specialPrice,
      this.maxSpecialPrice,
      this.discountInPercentage});

  MinMaxPrice.fromJson(Map<String, dynamic> json) {
    minPrice = json['min_price'];
    maxPrice = json['max_price'];
    specialPrice = json['special_price'];
    maxSpecialPrice = json['max_special_price'];
    discountInPercentage = json['discount_in_percentage'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['min_price'] = this.minPrice;
    data['max_price'] = this.maxPrice;
    data['special_price'] = this.specialPrice;
    data['max_special_price'] = this.maxSpecialPrice;
    data['discount_in_percentage'] = this.discountInPercentage;
    return data;
  }
}
