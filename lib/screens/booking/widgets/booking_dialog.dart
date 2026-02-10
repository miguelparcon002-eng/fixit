import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/config/supabase_config.dart';
import '../../../providers/booking_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/address_provider.dart';
import '../../../providers/rewards_provider.dart';
import '../../../models/redeemed_voucher.dart';
import '../../../core/utils/app_logger.dart';

class BookingDialog extends ConsumerStatefulWidget {
  final bool isEmergency;
  final bool isWeekBooking;

  const BookingDialog({super.key, this.isEmergency = false, this.isWeekBooking = false});

  @override
  ConsumerState<BookingDialog> createState() => _BookingDialogState();
}

class _BookingDialogState extends ConsumerState<BookingDialog> {
  int _currentStep = 0;
  final ScrollController _scrollController = ScrollController();

  // Step 1: Device selection
  String? _selectedDeviceType;
  final TextEditingController _modelController = TextEditingController();
  String? _selectedProblem;
  final TextEditingController _detailsController = TextEditingController();

  // Step 2: Time and location
  TimeOfDay _selectedTime = TimeOfDay.now();
  DateTime? _selectedDate;
  final TextEditingController _addressController = TextEditingController();
  String? _selectedTechnician;

  // Step 3: Promo code
  final TextEditingController _promoCodeController = TextEditingController();
  String? _appliedPromoCode;
  String? _appliedVoucherId; // ID of the redeemed voucher being used
  double _discountAmount = 0;
  String _discountType = 'none'; // 'percentage' or 'fixed'

  // Pricing map based on device type and problem (realistic PH prices)
  final Map<String, Map<String, double>> _pricing = {
    'Mobile Phone': {
      'Screen Cracked': 1500.0,
      'Battery Drains': 800.0,
      'Won\'t power on': 500.0,
      'Overheating': 450.0,
      'Water damage': 1200.0,
      'Software Bug': 350.0,
    },
    'Laptop': {
      'Screen Cracked': 3500.0,
      'Battery Drains': 2500.0,
      'Won\'t power on': 800.0,
      'Overheating': 650.0,
      'Water damage': 2000.0,
      'Software Bug': 500.0,
    },
  };

  final List<String> _problems = [
    'Screen Cracked',
    'Battery Drains',
    'Won\'t power on',
    'Overheating',
    'Water damage',
    'Software Bug',
  ];

  final List<Map<String, dynamic>> _technicians = [
    {'name': 'MetroFix', 'distance': '1.2km'},
    {'name': 'Estino', 'distance': '0.47km'},
    {'name': 'Sarsale', 'distance': '2.4km'},
    {'name': 'GizmoDoc', 'distance': '0.98km'},
  ];

  // Brand and model data for device selection with images
  final Map<String, Map<String, List<Map<String, String>>>> _deviceBrands = {
    'Mobile Phone': {
      'Apple': [
        {'name': 'iPhone 15 Pro Max', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/apple-iphone-15-pro-max.jpg'},
        {'name': 'iPhone 15 Pro', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/apple-iphone-15-pro.jpg'},
        {'name': 'iPhone 15', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/apple-iphone-15.jpg'},
        {'name': 'iPhone 14 Pro Max', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/apple-iphone-14-pro-max.jpg'},
        {'name': 'iPhone 14 Pro', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/apple-iphone-14-pro.jpg'},
        {'name': 'iPhone 14', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/apple-iphone-14.jpg'},
        {'name': 'iPhone 13', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/apple-iphone-13.jpg'},
        {'name': 'iPhone 12', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/apple-iphone-12.jpg'},
        {'name': 'iPhone SE', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/apple-iphone-se-2022.jpg'},
      ],
      'Samsung': [
        {'name': 'Galaxy S24 Ultra', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/samsung-galaxy-s24-ultra-5g.jpg'},
        {'name': 'Galaxy S24+', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/samsung-galaxy-s24+.jpg'},
        {'name': 'Galaxy S24', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/samsung-galaxy-s24.jpg'},
        {'name': 'Galaxy S23 Ultra', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/samsung-galaxy-s23-ultra-5g.jpg'},
        {'name': 'Galaxy S23', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/samsung-galaxy-s23.jpg'},
        {'name': 'Galaxy Z Fold 5', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/samsung-galaxy-z-fold5.jpg'},
        {'name': 'Galaxy Z Flip 5', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/samsung-galaxy-z-flip5.jpg'},
        {'name': 'Galaxy A54', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/samsung-galaxy-a54.jpg'},
        {'name': 'Galaxy A34', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/samsung-galaxy-a34.jpg'},
      ],
      'Xiaomi': [
        {'name': '14 Ultra', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/xiaomi-14-ultra.jpg'},
        {'name': '14 Pro', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/xiaomi-14-pro.jpg'},
        {'name': '14', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/xiaomi-14.jpg'},
        {'name': 'Redmi Note 13 Pro', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/xiaomi-redmi-note-13-pro-5g.jpg'},
        {'name': 'Redmi Note 13', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/xiaomi-redmi-note-13-5g.jpg'},
        {'name': 'Redmi 13C', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/xiaomi-redmi-13c.jpg'},
        {'name': 'POCO X6 Pro', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/xiaomi-poco-x6-pro.jpg'},
        {'name': 'POCO F5', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/xiaomi-poco-f5.jpg'},
      ],
      'OPPO': [
        {'name': 'Find X7 Ultra', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/oppo-find-x7-ultra.jpg'},
        {'name': 'Find X7', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/oppo-find-x7.jpg'},
        {'name': 'Reno 11 Pro', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/oppo-reno11-pro.jpg'},
        {'name': 'Reno 11', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/oppo-reno11.jpg'},
        {'name': 'A98', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/oppo-a98-5g.jpg'},
        {'name': 'A78', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/oppo-a78-5g.jpg'},
        {'name': 'A58', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/oppo-a58.jpg'},
      ],
      'Vivo': [
        {'name': 'X100 Pro', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/vivo-x100-pro.jpg'},
        {'name': 'X100', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/vivo-x100.jpg'},
        {'name': 'V30 Pro', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/vivo-v30-pro.jpg'},
        {'name': 'V30', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/vivo-v30.jpg'},
        {'name': 'Y100', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/vivo-y100.jpg'},
        {'name': 'Y36', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/vivo-y36.jpg'},
      ],
      'Realme': [
        {'name': 'GT 5 Pro', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/realme-gt5-pro.jpg'},
        {'name': 'GT Neo 5', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/realme-gt-neo5.jpg'},
        {'name': '12 Pro+', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/realme-12-proplus.jpg'},
        {'name': '12 Pro', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/realme-12-pro.jpg'},
        {'name': 'C67', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/realme-c67.jpg'},
        {'name': 'C55', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/realme-c55.jpg'},
      ],
      'Huawei': [
        {'name': 'P60 Pro', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/huawei-p60-pro.jpg'},
        {'name': 'P60', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/huawei-p60.jpg'},
        {'name': 'Mate 60 Pro', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/huawei-mate-60-pro.jpg'},
        {'name': 'Nova 12', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/huawei-nova-12.jpg'},
        {'name': 'Nova 11', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/huawei-nova-11.jpg'},
      ],
      'Google': [
        {'name': 'Pixel 8 Pro', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/google-pixel-8-pro.jpg'},
        {'name': 'Pixel 8', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/google-pixel-8.jpg'},
        {'name': 'Pixel 7a', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/google-pixel-7a.jpg'},
        {'name': 'Pixel 7', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/google-pixel-7.jpg'},
        {'name': 'Pixel 6a', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/google-pixel-6a.jpg'},
      ],
      'OnePlus': [
        {'name': '12', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/oneplus-12.jpg'},
        {'name': '12R', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/oneplus-12r.jpg'},
        {'name': 'Open', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/oneplus-open.jpg'},
        {'name': 'Nord 3', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/oneplus-nord-3.jpg'},
        {'name': 'Nord CE 3', 'image': 'https://fdn2.gsmarena.com/vv/bigpic/oneplus-nord-ce-3.jpg'},
      ],
    },
    'Laptop': {
      'Apple': [
        {'name': 'MacBook Pro 16" M3', 'image': 'https://store.storeimages.cdn-apple.com/4982/as-images.apple.com/is/mbp16-spacegray-select-202310?wid=400&hei=400&fmt=jpeg'},
        {'name': 'MacBook Pro 14" M3', 'image': 'https://store.storeimages.cdn-apple.com/4982/as-images.apple.com/is/mbp14-spacegray-select-202310?wid=400&hei=400&fmt=jpeg'},
        {'name': 'MacBook Air 15" M3', 'image': 'https://store.storeimages.cdn-apple.com/4982/as-images.apple.com/is/mba15-midnight-select-202306?wid=400&hei=400&fmt=jpeg'},
        {'name': 'MacBook Air 13" M3', 'image': 'https://store.storeimages.cdn-apple.com/4982/as-images.apple.com/is/mba13-midnight-select-202402?wid=400&hei=400&fmt=jpeg'},
        {'name': 'MacBook Air M2', 'image': 'https://store.storeimages.cdn-apple.com/4982/as-images.apple.com/is/macbook-air-midnight-select-20220606?wid=400&hei=400&fmt=jpeg'},
      ],
      'ASUS': [
        {'name': 'ROG Zephyrus G16', 'image': 'https://dlcdnwebimgs.asus.com/gain/D8E3F7A9-5B3E-4B1C-8B3A-1C5F3A9E3F7A/w400'},
        {'name': 'ROG Strix G16', 'image': 'https://dlcdnwebimgs.asus.com/gain/A1B2C3D4-5E6F-7A8B-9C0D-1E2F3A4B5C6D/w400'},
        {'name': 'TUF Gaming A15', 'image': 'https://dlcdnwebimgs.asus.com/gain/B2C3D4E5-6F7A-8B9C-0D1E-2F3A4B5C6D7E/w400'},
        {'name': 'ZenBook 14', 'image': 'https://dlcdnwebimgs.asus.com/gain/C3D4E5F6-7A8B-9C0D-1E2F-3A4B5C6D7E8F/w400'},
        {'name': 'VivoBook 15', 'image': 'https://dlcdnwebimgs.asus.com/gain/D4E5F6A7-8B9C-0D1E-2F3A-4B5C6D7E8F9A/w400'},
      ],
      'Lenovo': [
        {'name': 'ThinkPad X1 Carbon', 'image': 'https://p1-ofp.static.pub/medias/bWFzdGVyfHJvb3R8MjE0NzQ4fGltYWdlL3BuZ3xoYzUvaDc0LzE0MDY0MzQ3MjMzMzEwLnBuZ3w/w400'},
        {'name': 'ThinkPad T14', 'image': 'https://p2-ofp.static.pub/medias/bWFzdGVyfHJvb3R8MTc4NjIzfGltYWdlL3BuZ3xoYzgvaDAwLzE0MDY0MzY3MjU1NTgyLnBuZ3w/w400'},
        {'name': 'Legion Pro 7i', 'image': 'https://p3-ofp.static.pub/medias/bWFzdGVyfHJvb3R8MTU2NzgyfGltYWdlL3BuZ3xoNjgvaDZjLzE0MDY0Mzg3MjI4NzAyLnBuZ3w/w400'},
        {'name': 'Legion 5', 'image': 'https://p4-ofp.static.pub/medias/bWFzdGVyfHJvb3R8MTM0NTY3fGltYWdlL3BuZ3xoNTQvaDk4LzE0MDY0NDA3MjAyODMwLnBuZ3w/w400'},
        {'name': 'IdeaPad Slim 5', 'image': 'https://p1-ofp.static.pub/medias/bWFzdGVyfHJvb3R8MTIzNDU2fGltYWdlL3BuZ3xoMTIvaDM0LzE0MDY0NDI3MTc1OTU4LnBuZ3w/w400'},
      ],
      'HP': [
        {'name': 'Spectre x360', 'image': 'https://ssl-product-images.www8-hp.com/digmedialib/prodimg/lowres/c08441542.png'},
        {'name': 'Envy x360', 'image': 'https://ssl-product-images.www8-hp.com/digmedialib/prodimg/lowres/c08441543.png'},
        {'name': 'Pavilion 15', 'image': 'https://ssl-product-images.www8-hp.com/digmedialib/prodimg/lowres/c08441544.png'},
        {'name': 'Omen 16', 'image': 'https://ssl-product-images.www8-hp.com/digmedialib/prodimg/lowres/c08441545.png'},
        {'name': 'Victus 15', 'image': 'https://ssl-product-images.www8-hp.com/digmedialib/prodimg/lowres/c08441546.png'},
      ],
      'Dell': [
        {'name': 'XPS 15', 'image': 'https://i.dell.com/is/image/DellContent/content/dam/ss2/product-images/dell-client-products/notebooks/xps-notebooks/xps-15-9530/media-gallery/black/notebook-xps-15-9530-black-gallery-1.psd?wid=400'},
        {'name': 'XPS 13', 'image': 'https://i.dell.com/is/image/DellContent/content/dam/ss2/product-images/dell-client-products/notebooks/xps-notebooks/xps-13-9340/media-gallery/notebook-xps-13-9340-gallery-1.psd?wid=400'},
        {'name': 'Inspiron 15', 'image': 'https://i.dell.com/is/image/DellContent/content/dam/ss2/product-images/dell-client-products/notebooks/inspiron-notebooks/15-3520/media-gallery/notebook-inspiron-15-3520-gallery-1.psd?wid=400'},
        {'name': 'Alienware m16', 'image': 'https://i.dell.com/is/image/DellContent/content/dam/ss2/product-images/dell-client-products/notebooks/alienware-notebooks/alienware-m16-r2-intel/media-gallery/notebook-alienware-m16-r2-gallery-1.psd?wid=400'},
        {'name': 'Latitude 5540', 'image': 'https://i.dell.com/is/image/DellContent/content/dam/ss2/product-images/dell-client-products/notebooks/latitude-notebooks/latitude-15-5540/media-gallery/notebook-latitude-5540-gray-gallery-1.psd?wid=400'},
      ],
      'Acer': [
        {'name': 'Swift X 14', 'image': 'https://static.acer.com/up/Resource/Acer/Laptops/Swift_X/Images/20230209/acer-swift-x-sfx14-71g-702r.png'},
        {'name': 'Swift Go 14', 'image': 'https://static.acer.com/up/Resource/Acer/Laptops/Swift_Go/Images/20230209/acer-swift-go-sfg14-71-51dq.png'},
        {'name': 'Aspire 5', 'image': 'https://static.acer.com/up/Resource/Acer/Laptops/Aspire_5/Images/20230209/acer-aspire-5-a515-57-74q9.png'},
        {'name': 'Nitro 5', 'image': 'https://static.acer.com/up/Resource/Acer/Laptops/Nitro_5/Images/20230209/acer-nitro-5-an515-58.png'},
        {'name': 'Predator Helios 16', 'image': 'https://static.acer.com/up/Resource/Acer/Laptops/Predator_Helios/Images/20230209/acer-predator-helios-16.png'},
      ],
      'MSI': [
        {'name': 'Stealth 16', 'image': 'https://storage-asset.msi.com/global/picture/image/feature/nb/Stealth/Stealth-16-Studio/images/kv-nb.png'},
        {'name': 'Raider GE78', 'image': 'https://storage-asset.msi.com/global/picture/image/feature/nb/Raider/GE78-HX/images/kv-nb.png'},
        {'name': 'Katana 15', 'image': 'https://storage-asset.msi.com/global/picture/image/feature/nb/Katana/Katana-15/images/kv-nb.png'},
        {'name': 'Creator Z16', 'image': 'https://storage-asset.msi.com/global/picture/image/feature/nb/Creator/Creator-Z16/images/kv-nb.png'},
        {'name': 'Prestige 14', 'image': 'https://storage-asset.msi.com/global/picture/image/feature/nb/Prestige/Prestige-14/images/kv-nb.png'},
      ],
      'Samsung': [
        {'name': 'Galaxy Book 4 Pro', 'image': 'https://images.samsung.com/is/image/samsung/p6pim/ph/feature/164206622/ph-feature-galaxy-book4-pro-534940939?wid=400'},
        {'name': 'Galaxy Book 4', 'image': 'https://images.samsung.com/is/image/samsung/p6pim/ph/feature/164206623/ph-feature-galaxy-book4-534940940?wid=400'},
        {'name': 'Galaxy Book 3 Ultra', 'image': 'https://images.samsung.com/is/image/samsung/p6pim/ph/feature/164206624/ph-feature-galaxy-book3-ultra-534940941?wid=400'},
        {'name': 'Galaxy Book Go', 'image': 'https://images.samsung.com/is/image/samsung/p6pim/ph/feature/164206625/ph-feature-galaxy-book-go-534940942?wid=400'},
      ],
      'Huawei': [
        {'name': 'MateBook X Pro', 'image': 'https://consumer.huawei.com/content/dam/huawei-cbg-site/common/mkt/pdp/pc/matebook-x-pro-2023/img/huawei-matebook-x-pro-2023-kv.png'},
        {'name': 'MateBook 14', 'image': 'https://consumer.huawei.com/content/dam/huawei-cbg-site/common/mkt/pdp/pc/matebook-14-2023/img/huawei-matebook-14-2023-kv.png'},
        {'name': 'MateBook D16', 'image': 'https://consumer.huawei.com/content/dam/huawei-cbg-site/common/mkt/pdp/pc/matebook-d16-2023/img/huawei-matebook-d16-2023-kv.png'},
      ],
    },
  };

  String? _selectedBrand;

  @override
  void initState() {
    super.initState();
    // Ensure scroll starts at top
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });

    // Load default address from address provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final addressesAsync = ref.read(userAddressesProvider);
        addressesAsync.whenData((addresses) {
          if (addresses.isNotEmpty) {
            final defaultAddress = addresses.firstWhere(
              (address) => address.isDefault,
              orElse: () => addresses.first,
            );

            if (mounted) {
              setState(() {
                _addressController.text = defaultAddress.address;
              });
            }
          }
        });
      } catch (e) {
        // If there's an error or no addresses, just skip auto-fill
        debugPrint('Error loading default address: $e');
      }
    });
  }

  @override
  void dispose() {
    _modelController.dispose();
    _detailsController.dispose();
    _addressController.dispose();
    _promoCodeController.dispose();
    try {
      _scrollController.dispose();
    } catch (e) {
      // Ignore disposal errors on web
    }
    super.dispose();
  }

  void _applyPromoCode() {
    final code = _promoCodeController.text.trim().toUpperCase();
    final redeemedVouchersAsync = ref.read(redeemedVouchersProvider);

    // Check if it's a redeemed voucher (only unused ones)
    RedeemedVoucher? foundRedeemedVoucher;
    redeemedVouchersAsync.whenData((redeemedVouchers) {
      try {
        foundRedeemedVoucher = redeemedVouchers.firstWhere(
          (v) => !v.isUsed && code == 'VOUCHER${v.voucherId.toUpperCase()}',
        );
      } catch (e) {
        // No matching voucher found
      }
    });

    if (foundRedeemedVoucher != null) {
      setState(() {
        _appliedPromoCode = code;
        _appliedVoucherId = foundRedeemedVoucher!.id; // Store voucher ID for marking as used later
        _discountAmount = foundRedeemedVoucher!.discountAmount;
        _discountType = foundRedeemedVoucher!.discountType;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${foundRedeemedVoucher!.voucherTitle} applied successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      return;
    }

    // Check standard promo codes
    final Map<String, Map<String, dynamic>> promoCodes = {
      'FIRST20': {'type': 'percentage', 'amount': 20},
      'SAVE100': {'type': 'fixed', 'amount': 100},
      'SAVE250': {'type': 'fixed', 'amount': 250},
      'DISCOUNT10': {'type': 'percentage', 'amount': 10},
    };

    if (promoCodes.containsKey(code)) {
      final promo = promoCodes[code]!;
      setState(() {
        _appliedPromoCode = code;
        _appliedVoucherId = null; // No voucher ID for standard promo codes
        _discountAmount = promo['amount'].toDouble();
        _discountType = promo['type'];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Promo code applied successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid promo code'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removePromoCode() {
    setState(() {
      _appliedPromoCode = null;
      _appliedVoucherId = null;
      _discountAmount = 0;
      _discountType = 'none';
      _promoCodeController.clear();
    });
  }

  double _getServicePrice() {
    if (_selectedDeviceType == null || _selectedProblem == null) {
      return 500.0; // Default price
    }
    return _pricing[_selectedDeviceType]?[_selectedProblem] ?? 500.0;
  }

  double _getDistanceFee() {
    if (_selectedTechnician == null) return 0.0;
    final tech = _technicians.firstWhere(
      (t) => t['name'] == _selectedTechnician,
      orElse: () => {'distance': '0km'},
    );
    final distanceStr = tech['distance'] as String;
    // Parse distance (e.g., "1.2km" -> 1.2)
    final distance = double.tryParse(distanceStr.replaceAll('km', '')) ?? 0.0;
    // Calculate fee: 0.1km = ₱5, so 1km = ₱50
    return (distance / 0.1) * 5;
  }

  double _getBasePrice() {
    return _getServicePrice() + _getDistanceFee();
  }

  double _calculateTotal() {
    final basePrice = _getBasePrice();
    if (_appliedPromoCode == null) return basePrice;

    if (_discountType == 'percentage') {
      return basePrice - (basePrice * _discountAmount / 100);
    } else if (_discountType == 'fixed') {
      return basePrice - _discountAmount;
    }
    return basePrice;
  }

  void _nextStep() {
    if (_currentStep == 0) {
      // Validate step 1
      if (_selectedDeviceType == null || _modelController.text.isEmpty || _selectedProblem == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all required fields')),
        );
        return;
      }
    } else if (_currentStep == 1) {
      // Validate step 2
      if (_addressController.text.isEmpty || _selectedTechnician == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all required fields')),
        );
        return;
      }
    }

    if (_currentStep < 2) {
      setState(() => _currentStep++);
      // Reset scroll position to top when moving to next step
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      // Reset scroll position to top when moving to previous step
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      });
    }
  }

  void _confirmAppointment() async {
    try {
      // Get actual user details from profile
      final user = await ref.read(currentUserProvider.future);
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Calculate final total with any applied discount
      final finalTotal = _calculateTotal();

      // Combine date and time into scheduledDate
      DateTime scheduledDateTime;
      if (widget.isEmergency) {
        // Emergency: schedule for as soon as possible (now + 20 minutes)
        scheduledDateTime = DateTime.now().add(const Duration(minutes: 20));
      } else {
        // Regular booking: use selected date and time
        scheduledDateTime = DateTime(
          (_selectedDate ?? DateTime.now()).year,
          (_selectedDate ?? DateTime.now()).month,
          (_selectedDate ?? DateTime.now()).day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
      }

      // Create booking details text
      final basePrice = _getBasePrice();
      final bookingDetails = [
        'Device: ${_selectedDeviceType ?? "N/A"}',
        'Model: ${_modelController.text.trim()}',
        'Problem: ${_selectedProblem ?? "N/A"}',
        'Technician: ${_selectedTechnician ?? "TBD"}',
        if (_detailsController.text.trim().isNotEmpty) 'Details: ${_detailsController.text.trim()}',
        if (_appliedPromoCode != null) ...[
          'Promo Code: $_appliedPromoCode',
          'Original Price: ₱${basePrice.toStringAsFixed(2)}',
          'Discount: ${_discountType == "percentage" ? "$_discountAmount%" : "₱$_discountAmount"}',
        ],
        if (widget.isEmergency) 'Priority: EMERGENCY',
        if (widget.isWeekBooking) 'Priority: Week booking',
      ].join('\n');

      // Get all users to find a technician
      final supabase = SupabaseConfig.client;
      
      // Try to find a technician user
      String technicianId;
      try {
        // First, try to find technician with email fixittechnician@gmail.com (Ethan)
        var techResponse = await supabase
            .from('users')
            .select('id, email, full_name, role')
            .eq('email', 'fixittechnician@gmail.com')
            .maybeSingle();
        
        // If Ethan not found, try any technician
        if (techResponse == null) {
          AppLogger.p('Ethan not found, looking for any technician...');
          techResponse = await supabase
              .from('users')
              .select('id, email, full_name, role')
              .eq('role', 'technician')
              .limit(1)
              .maybeSingle();
        }
        
        if (techResponse != null) {
          technicianId = techResponse['id'] as String;
          AppLogger.p('✅ Found technician: ${techResponse['full_name']} (${techResponse['email']}) - ID: $technicianId');
        } else {
          AppLogger.p('❌ No technicians found in database');
          throw Exception('No technicians available. Please ensure Ethan Estino (fixittechnician@gmail.com) has role="technician" in the users table.');
        }
      } catch (e) {
        AppLogger.p('❌ Error fetching technician: $e');
        if (e is Exception && e.toString().contains('technician')) {
          rethrow;
        }
        throw Exception('Unable to find technicians. Please check database setup.');
      }

      // Get or create a service ID
      String serviceId;
      try {
        // First, try to find an existing service for this technician
        var serviceResponse = await supabase
            .from('services')
            .select('id, technician_id, service_name')
            .eq('technician_id', technicianId)
            .limit(1)
            .maybeSingle();
        
        // If no service for this technician, try to find any service
        if (serviceResponse == null) {
          AppLogger.p('No service found for technician $technicianId, checking for any service...');
          serviceResponse = await supabase
              .from('services')
              .select('id, technician_id, service_name')
              .limit(1)
              .maybeSingle();
        }
        
        if (serviceResponse != null) {
          serviceId = serviceResponse['id'] as String;
          AppLogger.p('✅ Using existing service: ${serviceResponse['service_name']} (ID: $serviceId)');
        } else {
          // No service exists at all - this needs manual creation due to RLS
          AppLogger.p('❌ No services found in database');
          throw Exception(
            'No services available. Please create a service for Ethan Estino first.\n\n'
            'Run this SQL in Supabase:\n'
            'INSERT INTO public.services (technician_id, service_name, description, category, estimated_duration, is_active)\n'
            'VALUES (\'$technicianId\', \'General Repair\', \'Device repair service\', \'Repair\', 60, true);'
          );
        }
      } catch (e) {
        AppLogger.p('❌ Error with service: $e');
        if (e is Exception) {
          rethrow;
        }
        throw Exception('Unable to access services. Please check database setup.');
      }

      // Create booking in Supabase using BookingService
      final bookingService = ref.read(bookingServiceProvider);
      
      final createdBooking = await bookingService.createBooking(
        customerId: user.id,
        technicianId: technicianId,
        serviceId: serviceId,
        scheduledDate: scheduledDateTime,
        customerAddress: _addressController.text.trim(),
        customerLatitude: null,
        customerLongitude: null,
        estimatedCost: finalTotal,
      );

      // Update diagnostic notes with booking details
      await bookingService.updateDiagnosticNotes(
        bookingId: createdBooking.id,
        notes: bookingDetails,
        finalCost: finalTotal,
      );

      // If a voucher was applied, mark it as used
      if (_appliedVoucherId != null) {
        final voucherService = ref.read(redeemedVoucherServiceProvider);
        await voucherService.markVoucherAsUsed(
          voucherId: _appliedVoucherId!,
          bookingId: createdBooking.id,
        );
        // Refresh voucher providers
        ref.invalidate(redeemedVouchersProvider);
        ref.invalidate(unusedVouchersProvider);
      }

      // Force refresh the customer bookings provider to show the new booking immediately
      ref.invalidate(customerBookingsProvider);

      // Show success dialog
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, size: 60, color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Request Successful!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close success dialog
                        Navigator.of(context).pop(); // Close booking dialog
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.deepBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'OK',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      AppLogger.p('Error creating booking: $e');
      if (context.mounted) {
        // Show user-friendly error message
        String errorMessage = 'Error creating booking';
        if (e.toString().contains('technician')) {
          errorMessage = 'No technicians available. Please contact support.';
        } else if (e.toString().contains('service')) {
          errorMessage = 'Service setup incomplete. Please contact support.';
        } else if (e.toString().contains('PostgrestException')) {
          errorMessage = 'Database error. Please ensure all setup is complete.';
        } else {
          errorMessage = e.toString().replaceAll('Exception: ', '');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with progress indicator
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryCyan.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      if (_currentStep > 0)
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios, size: 20),
                          onPressed: _previousStep,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          style: IconButton.styleFrom(
                            foregroundColor: AppTheme.deepBlue,
                          ),
                        ),
                      const Spacer(),
                      Text(
                        _currentStep == 0
                            ? 'Device Details'
                            : _currentStep == 1
                                ? 'Schedule & Location'
                                : 'Confirmation',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.deepBlue,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, size: 24),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        style: IconButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Progress indicator
                  Row(
                    children: List.generate(3, (index) {
                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.only(
                            right: index < 2 ? 8 : 0,
                          ),
                          height: 4,
                          decoration: BoxDecoration(
                            color: index <= _currentStep
                                ? AppTheme.deepBlue
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(24),
                child: _currentStep == 0
                    ? _buildDeviceSelectionStep()
                    : _currentStep == 1
                        ? _buildTimeLocationStep()
                        : _buildConfirmationStep(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceSelectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose your device',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textSecondaryColor),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DeviceTypeButton(
                icon: Icons.smartphone,
                label: 'Mobile Phone',
                isSelected: _selectedDeviceType == 'Mobile Phone',
                onTap: () => setState(() {
                  _selectedDeviceType = 'Mobile Phone';
                  _selectedBrand = null; // Reset brand when device type changes
                }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DeviceTypeButton(
                icon: Icons.laptop,
                label: 'Laptop',
                isSelected: _selectedDeviceType == 'Laptop',
                onTap: () => setState(() {
                  _selectedDeviceType = 'Laptop';
                  _selectedBrand = null; // Reset brand when device type changes
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Model',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textSecondaryColor),
        ),
        const SizedBox(height: 8),
        Text(
          'Type your model or select from popular devices below',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _modelController,
          onChanged: (value) {
            // Clear brand selection when typing manually
            if (_selectedBrand != null && value.isNotEmpty) {
              setState(() => _selectedBrand = null);
            }
          },
          decoration: InputDecoration(
            hintText: 'ex. iPhone 14 Pro, MacBook Air M2',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
            filled: true,
            fillColor: Colors.grey[50],
            prefixIcon: Icon(Icons.edit, color: Colors.grey[400], size: 20),
            suffixIcon: _modelController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey[400], size: 20),
                    onPressed: () {
                      setState(() {
                        _modelController.clear();
                        _selectedBrand = null;
                      });
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.deepBlue, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
        // Show brand/model selector when device type is selected
        if (_selectedDeviceType != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.help_outline, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      "Don't know your model? Browse by brand:",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Brand selector - horizontal scroll
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _deviceBrands[_selectedDeviceType]?.keys.length ?? 0,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final brand = _deviceBrands[_selectedDeviceType]!.keys.elementAt(index);
                      final isSelected = _selectedBrand == brand;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            if (_selectedBrand == brand) {
                              _selectedBrand = null; // Deselect if already selected
                            } else {
                              _selectedBrand = brand;
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.deepBlue : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSelected ? AppTheme.deepBlue : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Text(
                            brand,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Model selector - show when brand is selected
                if (_selectedBrand != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    '$_selectedBrand Models:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _deviceBrands[_selectedDeviceType]?[_selectedBrand]?.length ?? 0,
                      separatorBuilder: (context, index) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final modelData = _deviceBrands[_selectedDeviceType]![_selectedBrand]![index];
                        final modelName = modelData['name']!;
                        final modelImage = modelData['image']!;
                        final displayName = _selectedDeviceType == 'Mobile Phone'
                            ? '$_selectedBrand $modelName'
                            : modelName; // Laptops usually have full names
                        final isSelected = _modelController.text == displayName;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _modelController.text = displayName;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 100,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.deepBlue.withValues(alpha: 0.1) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppTheme.deepBlue : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Device image
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    modelImage,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          _selectedDeviceType == 'Mobile Phone' ? Icons.smartphone : Icons.laptop,
                                          size: 30,
                                          color: Colors.grey[500],
                                        ),
                                      );
                                    },
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Center(
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.deepBlue),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  modelName,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    color: isSelected ? AppTheme.deepBlue : AppTheme.textPrimaryColor,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        const Text(
          'What\'s the problem?',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textSecondaryColor),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _problems.map((problem) {
            final isSelected = _selectedProblem == problem;
            return InkWell(
              onTap: () => setState(() => _selectedProblem = problem),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.deepBlue : Colors.grey[50],
                  border: Border.all(
                    color: isSelected ? AppTheme.deepBlue : Colors.grey.shade200,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  problem,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        const Text(
          'More details (optional)',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textSecondaryColor),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _detailsController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Add any details: when it started, previous repairs, etc.',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.deepBlue, width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 24),
        // Price Display
        if (_selectedDeviceType != null && _selectedProblem != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.deepBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.deepBlue.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.attach_money, color: AppTheme.deepBlue, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Service Price',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ],
                ),
                Text(
                  '₱${_getServicePrice().toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.deepBlue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '* Distance fee will be added based on technician selection',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.deepBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Next',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeLocationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show date picker for week bookings
        if (widget.isWeekBooking) ...[
          const Text(
            'Select Date',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textSecondaryColor),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final now = DateTime.now();
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? now,
                firstDate: now,
                lastDate: now.add(const Duration(days: 7)),
              );
              if (date != null) {
                setState(() => _selectedDate = date);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, color: AppTheme.deepBlue, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        _selectedDate != null
                            ? DateFormat('MMM dd, yyyy').format(_selectedDate!)
                            : 'Choose a date',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: _selectedDate != null ? AppTheme.textPrimaryColor : Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        // Hide time slot for emergency repairs, show for week and regular bookings
        if (!widget.isEmergency) ...[
          const Text(
            'Time Slot',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textSecondaryColor),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: _selectedTime,
              );
              if (time != null) {
                setState(() => _selectedTime = time);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time, color: AppTheme.deepBlue, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        _selectedTime.format(context),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (widget.isEmergency) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.bolt, color: AppTheme.warningColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Emergency Service',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Technician will arrive ASAP (15-20 mins)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
        const Text(
          'Address',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textSecondaryColor),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _addressController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Enter street, building or exact address',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            filled: true,
            fillColor: Colors.grey[50],
            prefixIcon: Padding(
              padding: const EdgeInsets.only(top: 12, left: 12),
              child: Icon(Icons.location_on, color: Colors.grey[400], size: 20),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.deepBlue, width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Available Technicians',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textSecondaryColor),
        ),
        const SizedBox(height: 4),
        Text(
          'Distance fee: ₱5 per 0.1km',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: _technicians.asMap().entries.map((entry) {
              final index = entry.key;
              final tech = entry.value;
              final isSelected = _selectedTechnician == tech['name'];
              final distanceStr = tech['distance'] as String;
              final distance = double.tryParse(distanceStr.replaceAll('km', '')) ?? 0.0;
              final distanceFee = (distance / 0.1) * 5;
              return Column(
                children: [
                  InkWell(
                    onTap: () => setState(() => _selectedTechnician = tech['name']),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.deepBlue.withValues(alpha: 0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.deepBlue : Colors.grey[300],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.person,
                              color: isSelected ? Colors.white : Colors.grey[600],
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tech['name'],
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                    color: AppTheme.textPrimaryColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(Icons.location_on, size: 12, color: AppTheme.successColor),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${tech['distance']} away',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '+₱${distanceFee.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? AppTheme.deepBlue : Colors.grey[600],
                                ),
                              ),
                              if (isSelected)
                                Icon(Icons.check_circle, color: AppTheme.deepBlue, size: 18),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (index < _technicians.length - 1)
                    Divider(height: 1, color: Colors.grey.shade200, indent: 16, endIndent: 16),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _nextStep,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.deepBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Next',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationStep() {
    final basePrice = _getBasePrice();
    final total = _calculateTotal();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(
                icon: Icons.devices,
                label: 'Device',
                value: '$_selectedDeviceType - ${_modelController.text}',
              ),
              const SizedBox(height: 16),
              _InfoRow(
                icon: Icons.build,
                label: 'Issue',
                value: _selectedProblem ?? '',
              ),
              const SizedBox(height: 16),
              _InfoRow(
                icon: Icons.schedule,
                label: 'When',
                value: widget.isEmergency
                    ? 'ASAP (15-20 mins)'
                    : '${DateFormat('MMM dd, yyyy').format(_selectedDate ?? DateTime.now())}, ${_selectedTime.format(context)}',
              ),
              const SizedBox(height: 16),
              _InfoRow(
                icon: Icons.location_on,
                label: 'Address',
                value: _addressController.text,
              ),
              const SizedBox(height: 16),
              _InfoRow(
                icon: Icons.person,
                label: 'Technician',
                value: _selectedTechnician ?? 'Not selected',
              ),
              if (_detailsController.text.isNotEmpty) ...[
                const SizedBox(height: 16),
                _InfoRow(
                  icon: Icons.notes,
                  label: 'Additional Details',
                  value: _detailsController.text,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Promo Code Section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.local_offer, size: 20, color: AppTheme.warningColor),
                  const SizedBox(width: 8),
                  const Text(
                    'Have a promo code?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_appliedPromoCode == null) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _promoCodeController,
                        decoration: InputDecoration(
                          hintText: 'Enter code',
                          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.deepBlue, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        textCapitalization: TextCapitalization.characters,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _applyPromoCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.deepBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Apply',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.successColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: AppTheme.successColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _appliedPromoCode!,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                            Text(
                              _discountType == 'percentage'
                                  ? '$_discountAmount% discount applied'
                                  : '₱${_discountAmount.toStringAsFixed(0)} discount applied',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: _removePromoCode,
                        color: Colors.grey[600],
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Price Summary
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.deepBlue, AppTheme.lightBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Service Fee
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Service Fee',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  Text(
                    '₱${_getServicePrice().toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Distance Fee
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Distance Fee',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${_technicians.firstWhere((t) => t['name'] == _selectedTechnician)['distance']})',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '₱${_getDistanceFee().toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              if (_appliedPromoCode != null) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Discount',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    Text(
                      _discountType == 'percentage'
                          ? '-₱${(basePrice * _discountAmount / 100).toStringAsFixed(0)}'
                          : '-₱${_discountAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.warningColor,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Divider(color: Colors.white.withValues(alpha: 0.3), height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '₱${total.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _confirmAppointment,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.deepBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Confirm Appointment',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _previousStep,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.deepBlue,
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: AppTheme.deepBlue, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Edit Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

class _DeviceTypeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DeviceTypeButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.deepBlue : Colors.grey[50],
          border: Border.all(
            color: isSelected ? AppTheme.deepBlue : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 36,
              color: isSelected ? Colors.white : AppTheme.deepBlue,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.deepBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppTheme.deepBlue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
