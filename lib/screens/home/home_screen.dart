import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../models/course.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/course_card.dart';
import '../../widgets/shimmer_loading.dart';
import '../courses/course_list_screen.dart';
import '../courses/course_detail_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';
import '../wishlist/wishlist_screen.dart';

class HomeScreen extends StatefulWidget {
  static const route = '/home';
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTabIndex = 0;
  Map<String, dynamic>? _user;
  List<Course> _featuredCourses = [];
  List<Course> _popularCourses = [];
  List<Course> _enrolledCourses = [];
  bool _isLoadingFeatured = true;
  bool _isLoadingPopular = true;
  bool _isLoadingEnrolled = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadCourses();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await AuthService.instance.currentUser;
      if (mounted) setState(() => _user = user);
    } catch (_) {}
  }

  Future<void> _loadCourses() async {
    await Future.wait([
      _loadFeaturedCourses(),
      _loadPopularCourses(),
      _loadEnrolledCourses(),
    ]);
  }

  Future<void> _loadFeaturedCourses() async {
    setState(() => _isLoadingFeatured = true);
    try {
      final courses = await ApiService.instance.getFeaturedCourses();
      if (mounted) setState(() => _featuredCourses = courses);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingFeatured = false);
    }
  }

  Future<void> _loadPopularCourses() async {
    setState(() => _isLoadingPopular = true);
    try {
      final courses = await ApiService.instance.getPopularCourses();
      if (mounted) setState(() => _popularCourses = courses);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingPopular = false);
    }
  }

  Future<void> _loadEnrolledCourses() async {
    setState(() => _isLoadingEnrolled = true);
    try {
      final courses = await ApiService.instance.getEnrolledCourses();
      if (mounted) setState(() => _enrolledCourses = courses);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingEnrolled = false);
    }
  }

  Future<void> _onRefresh() async {
    await _loadCourses();
  }

  void _onTabTapped(int index) {
    setState(() => _currentTabIndex = index);
  }

  Widget _buildCurrentTab() {
    switch (_currentTabIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return const CourseListScreen();
      case 2:
        return const WishlistScreen();
      case 3:
        return const ProfileScreen();
      case 4:
        return const SettingsScreen();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    final config = AppConfig.of(context);

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: config.primaryColor,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(child: _buildWelcomeBanner(config)),
          SliverToBoxAdapter(child: _buildSearchBar(config)),
          if (_enrolledCourses.isNotEmpty)
            SliverToBoxAdapter(child: _buildSectionHeader('Continue Learning', config)),
          if (_enrolledCourses.isNotEmpty)
            SliverToBoxAdapter(child: _buildEnrolledCarousel(config)),
          SliverToBoxAdapter(child: _buildSectionHeader('Featured Courses', config)),
          SliverToBoxAdapter(child: _buildFeaturedCourses(config)),
          SliverToBoxAdapter(child: _buildSectionHeader('Popular Courses', config)),
          SliverToBoxAdapter(child: _buildPopularCourses(config)),
          SliverToBoxAdapter(child: _buildSectionHeader('Categories', config)),
          SliverToBoxAdapter(child: _buildCategoriesGrid(config)),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner(AppConfig config) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';
    final firstName = _user?['name']?.split(' ').first ?? 'Learner';

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [config.primaryColor, config.primaryColorDark],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: config.primaryColor.withOpacity( 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$greeting,',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity( 0.85),
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            firstName,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Continue your learning journey. You\'re doing great!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity( 0.8),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(AppConfig config) {
    return GestureDetector(
      onTap: () {
        setState(() => _currentTabIndex = 1);
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity( 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity( 0.1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search,
              color: Theme.of(context).colorScheme.onSurface.withOpacity( 0.4),
            ),
            const SizedBox(width: 12),
            Text(
              'Search courses...',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity( 0.4),
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, AppConfig config) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _currentTabIndex = 1),
            child: Text(
              'View All',
              style: TextStyle(color: config.primaryColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnrolledCarousel(AppConfig config) {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _enrolledCourses.length,
        itemBuilder: (context, index) {
          final course = _enrolledCourses[index];
          return _EnrolledCourseCard(
            course: course,
            primaryColor: config.primaryColor,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CourseDetailScreen(courseId: course.id.toString()),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedCourses(AppConfig config) {
    if (_isLoadingFeatured) {
      return const SizedBox(
        height: 260,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_featuredCourses.isEmpty) {
      return _buildEmptySection('No featured courses available');
    }
    return SizedBox(
      height: 260,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _featuredCourses.length,
        itemBuilder: (context, index) {
          final course = _featuredCourses[index];
          return CourseCard(
            thumbnailUrl: course.thumbnail,
            title: course.title,
            instructorName: course.instructor.name,
            rating: course.rating,
            ratingCount: course.ratingCount,
            price: course.price,
            salePrice: course.salePrice,
            isFree: course.isFree,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CourseDetailScreen(courseId: course.id.toString()),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPopularCourses(AppConfig config) {
    if (_isLoadingPopular) {
      return _buildShimmerGrid();
    }
    if (_popularCourses.isEmpty) {
      return _buildEmptySection('No popular courses available');
    }
    return SizedBox(
      height: 260,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _popularCourses.length,
        itemBuilder: (context, index) {
          final course = _popularCourses[index];
          return CourseCard(
            thumbnailUrl: course.thumbnail,
            title: course.title,
            instructorName: course.instructor.name,
            rating: course.rating,
            ratingCount: course.ratingCount,
            price: course.price,
            salePrice: course.salePrice,
            isFree: course.isFree,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CourseDetailScreen(courseId: course.id.toString()),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoriesGrid(AppConfig config) {
    final categories = config.categories;

    if (categories.isEmpty) {
      return _buildEmptySection('No categories available');
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.0,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return GestureDetector(
            onTap: () {
              setState(() => _currentTabIndex = 1);
            },
            child: Container(
              decoration: BoxDecoration(
                color: config.primaryColor.withOpacity( 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: config.primaryColor.withOpacity( 0.12),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getCategoryIcon(category.name),
                    size: 32,
                    color: config.primaryColor,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getCategoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('web') || lower.contains('frontend')) return Icons.language;
    if (lower.contains('mobile') || lower.contains('flutter')) return Icons.phone_iphone;
    if (lower.contains('design')) return Icons.palette;
    if (lower.contains('data') || lower.contains('ai')) return Icons.analytics;
    if (lower.contains('backend') || lower.contains('server')) return Icons.dns;
    if (lower.contains('business') || lower.contains('market')) return Icons.trending_up;
    if (lower.contains('photo') || lower.contains('video')) return Icons.videocam;
    return Icons.category;
  }

  Widget _buildEmptySection(String message) {
    return SizedBox(
      height: 120,
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity( 0.4),
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return SizedBox(
      height: 260,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 3,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: SizedBox(width: 200, height: 260, child: ShimmerLoading(child: SizedBox.expand())),
        ),
      ),
    );
  }

  List<BottomNavigationBarItem> _buildNavItems(AppConfig config) {
    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
      const BottomNavigationBarItem(icon: Icon(Icons.library_books_outlined), activeIcon: Icon(Icons.library_books), label: 'Courses'),
      const BottomNavigationBarItem(icon: Icon(Icons.favorite_outline), activeIcon: Icon(Icons.favorite), label: 'Wishlist'),
    ];

    if (config.showProfileTab) {
      items.add(const BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'));
    }
    if (config.showSettingsTab) {
      items.add(const BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: 'Settings'));
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final config = AppConfig.of(context);
    final isInstructor = _user?['role'] == 'instructor';

    return Scaffold(
      body: SafeArea(child: _buildCurrentTab()),
      floatingActionButton: isInstructor
          ? FloatingActionButton(
              onPressed: () {},
              backgroundColor: config.primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: config.primaryColor,
        unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity( 0.4),
        selectedFontSize: 12,
        unselectedFontSize: 12,
        elevation: 8,
        items: _buildNavItems(config),
      ),
    );
  }
}

class _EnrolledCourseCard extends StatelessWidget {
  final Course course;
  final Color primaryColor;
  final VoidCallback onTap;

  const _EnrolledCourseCard({
    required this.course,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity( 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                height: 80,
                width: double.infinity,
                color: primaryColor.withOpacity( 0.1),
                child: course.thumbnail.isNotEmpty
                    ? Image.network(course.thumbnail, fit: BoxFit.cover)
                    : Icon(Icons.play_circle_fill, size: 36, color: primaryColor),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      course.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: course.progress,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                            minHeight: 5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(course.progress * 100).toInt()}% Complete',
                          style: TextStyle(fontSize: 11, color: primaryColor, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
