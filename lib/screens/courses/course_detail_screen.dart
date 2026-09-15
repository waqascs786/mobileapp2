import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/app_config.dart';
import '../../models/course.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class CourseDetailScreen extends StatefulWidget {
  static const route = '/course-detail';
  final String courseId;

  const CourseDetailScreen({super.key, required this.courseId});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Course? _course;
  List<dynamic> _reviews = [];
  bool _isLoading = true;
  bool _isLoadingReviews = true;
  bool _isWishlisted = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCourseDetail();
    _loadReviews();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCourseDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await ApiService.instance.getCourse(widget.courseId);
      if (!mounted) return;
      final courseData = data['data'] ?? data;
      if (courseData is! Map<String, dynamic>) {
        throw Exception('Invalid course data format');
      }
      final course = Course.fromJson(courseData);
      if (!mounted) return;
      setState(() {
        _course = course;
        _isWishlisted = course.isWishlisted;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load course details. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoadingReviews = true);
    try {
      final reviews = await ApiService.instance.getCourseReviews(int.tryParse(widget.courseId) ?? 0);
      if (mounted) setState(() => _reviews = reviews);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingReviews = false);
    }
  }

  Future<void> _toggleWishlist() async {
    final wasWishlisted = _isWishlisted;
    setState(() => _isWishlisted = !_isWishlisted);

    try {
      if (wasWishlisted) {
        await ApiService.instance.removeFromWishlist(widget.courseId);
      } else {
        await ApiService.instance.addToWishlist(widget.courseId);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isWishlisted = wasWishlisted);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update wishlist')),
        );
      }
    }
  }

  Future<void> _shareCourse() async {
    if (_course == null) return;
    final config = AppConfig.of(context);
    final url = '${config.wpBaseUrl}/courses/${_course!.id}';
    await Clipboard.setData(ClipboardData(text: url));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course link copied to clipboard')),
      );
    }
  }

  Future<void> _handleEnrollTap() async {
    final isAuthenticated = AuthService.instance.isAuthenticated;
    if (!mounted) return;

    if (!isAuthenticated) {
      _showLoginPrompt();
      return;
    }

    if (_course == null) return;

    if (_course!.isEnrolled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Opening course content...')),
      );
    } else {
      _showEnrollConfirmation();
    }
  }

  void _showLoginPrompt() {
    final config = AppConfig.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.login, size: 48, color: config.primaryColor),
            const SizedBox(height: 16),
            const Text(
              'Login Required',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Please login to enroll in this course',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context).pushNamed('/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: config.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Login'),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showEnrollConfirmation() {
    final config = AppConfig.of(context);
    final price = _course!.price;
    final isFree = price == 0;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Icon(
              isFree ? Icons.card_giftcard : Icons.shopping_cart,
              size: 48,
              color: config.primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              isFree ? 'Enroll for Free' : 'Enroll in Course',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              isFree
                  ? 'Start learning for free!'
                  : 'You will be charged \$${price.toStringAsFixed(2)}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _processEnrollment();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: config.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(isFree ? 'Enroll Now' : 'Proceed to Payment'),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _processEnrollment() async {
    try {
      await ApiService.instance.enrollCourse(int.tryParse(widget.courseId) ?? 0);
      if (!mounted) return;
      _loadCourseDetail();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully enrolled!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enrollment failed. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      return _buildContent(context);
    } catch (e, stack) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Something went wrong',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _error = null;
                    });
                    _loadCourseDetail();
                    _loadReviews();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildContent(BuildContext context) {
    final config = AppConfig.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  _loadCourseDetail();
                  _loadReviews();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final course = _course;

    if (course == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: Text('No course data')),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(course, config),
          SliverToBoxAdapter(child: _buildCourseInfo(course, config)),
          SliverToBoxAdapter(child: _buildTabBar(config)),
          SliverToBoxAdapter(
            child: SizedBox(
              height: _calculateTabContentHeight(course),
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCurriculumTab(course, config),
                  _buildOverviewTab(course, config),
                  _buildReviewsTab(config),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomBar(course, config),
    );
  }

  Widget _buildSliverAppBar(Course course, AppConfig config) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      stretch: true,
      backgroundColor: config.primaryColor,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isWishlisted ? Icons.favorite : Icons.favorite_border,
              size: 20,
              color: _isWishlisted ? Colors.red : Colors.white,
            ),
          ),
          onPressed: _toggleWishlist,
        ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.share, size: 20, color: Colors.white),
          ),
          onPressed: _shareCourse,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: 'course-hero-${course.id}',
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  config.primaryColor,
                  config.primaryColorDark,
                ],
              ),
            ),
            child: course.thumbnail.isNotEmpty
                ? Image.network(
                    course.thumbnail,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  )
                : Center(
                    child: Icon(
                      Icons.play_circle_fill,
                      size: 72,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildCourseInfo(Course course, AppConfig config) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (course.categories.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: course.categories
                  .take(2)
                  .map((cat) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: config.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: config.primaryColor,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          const SizedBox(height: 12),
          Text(
            course.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: config.primaryColor.withOpacity(0.1),
                child: Text(
                  course.instructor.name.initials,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: config.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                course.instructor.name,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildInfoChip(Icons.star_rounded, '${course.rating}', Colors.amber),
              const SizedBox(width: 12),
              _buildInfoChip(Icons.people_outline, '${course.studentsCount} students', null),
              const SizedBox(width: 12),
              _buildInfoChip(Icons.schedule, course.duration, null),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color? iconColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: iconColor ?? Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(AppConfig config) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: config.primaryColor,
        unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
        indicatorColor: config.primaryColor,
        indicatorWeight: 3,
        tabs: const [
          Tab(text: 'Curriculum'),
          Tab(text: 'Overview'),
          Tab(text: 'Reviews'),
        ],
      ),
    );
  }

  Widget _buildCurriculumTab(Course course, AppConfig config) {
    if (course.curriculum.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No curriculum available'),
        ),
      );
    }

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: course.curriculum.length,
      itemBuilder: (context, index) {
        final section = course.curriculum[index];
        return _CurriculumSectionWidget(
          section: section,
          primaryColor: config.primaryColor,
          isExpanded: course.curriculum.length == 1,
        );
      },
    );
  }

  Widget _buildOverviewTab(Course course, AppConfig config) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (course.description.isNotEmpty) ...[
            Text(
              'Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              course.description,
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (course.tags.isNotEmpty) ...[
            Text(
              "What you'll learn",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            ...course.tags.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle, size: 20, color: config.primaryColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 24),
          ],
          if (course.shortDescription.isNotEmpty) ...[
            Text(
              'Requirements',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.circle, size: 6, color: config.primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      course.shortDescription,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildReviewsTab(AppConfig config) {
    if (_isLoadingReviews) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rate_review_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No reviews yet',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    final avgRating = _reviews.isEmpty
        ? 0.0
        : _reviews.map((r) => (r['rating'] as num?)?.toDouble() ?? 0.0).reduce((a, b) => a + b) / _reviews.length;
    final ratingCounts = List.generate(5, (i) {
      return _reviews.where((r) => (r['rating'] as num?)?.toInt() == 5 - i).length;
    });
    final totalReviews = _reviews.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRatingSummary(avgRating, ratingCounts, totalReviews, config),
          const SizedBox(height: 24),
          ..._reviews.map((review) => _buildReviewCard(review, config)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildRatingSummary(double avg, List<int> counts, int total, AppConfig config) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Text(
              avg.toStringAsFixed(1),
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Row(
              children: List.generate(
                5,
                (i) => Icon(
                  i < avg.round() ? Icons.star_rounded : Icons.star_border_rounded,
                  color: Colors.amber,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$total reviews',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            children: List.generate(5, (i) {
              final starCount = counts[i];
              final fraction = total > 0 ? starCount / total : 0.0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    SizedBox(
                      width: 32,
                      child: Text(
                        '${5 - i}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: fraction,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(config.primaryColor),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 24,
                      child: Text(
                        '$starCount',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(dynamic review, AppConfig config) {
    final userName = review['userName'] as String? ?? 'Anonymous';
    final rating = (review['rating'] as num?)?.toInt() ?? 0;
    final comment = review['comment'] as String? ?? '';
    final date = review['date'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: config.primaryColor.withOpacity(0.1),
                child: Text(
                  userName.initials,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: config.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < rating ? Icons.star_rounded : Icons.star_border_rounded,
                    color: Colors.amber,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            comment,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(Course course, AppConfig config) {
    final isEnrolled = course.isEnrolled;
    final isFree = course.price == 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (!isEnrolled) ...[
              Text(
                isFree ? 'Free' : '\$${course.price.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: config.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _handleEnrollTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: config.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    isEnrolled ? 'Continue Learning' : 'Enroll Now',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateTabContentHeight(Course course) {
    final maxSections = course.curriculum.length;
    final totalLessons = course.curriculum.fold<int>(0, (sum, s) => sum + s.items.length);
    final curriculumHeight = (maxSections * 56.0) + (totalLessons * 48.0);
    return 400.0 + curriculumHeight;
  }
}

class _CurriculumSectionWidget extends StatefulWidget {
  final CurriculumSection section;
  final Color primaryColor;
  final bool isExpanded;

  const _CurriculumSectionWidget({
    required this.section,
    required this.primaryColor,
    this.isExpanded = false,
  });

  @override
  State<_CurriculumSectionWidget> createState() => _CurriculumSectionWidgetState();
}

class _CurriculumSectionWidgetState extends State<_CurriculumSectionWidget> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.isExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.section.sectionTitle,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.section.items.length} lessons',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down, size: 24),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: widget.section.items.map((lesson) {
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  leading: Icon(
                    lesson.isCompleted
                        ? Icons.check_circle
                        : lesson.type == CurriculumItemType.quiz
                            ? Icons.help_outline
                            : Icons.play_circle_outline,
                    size: 22,
                    color: lesson.isCompleted
                        ? Colors.green
                        : widget.primaryColor,
                  ),
                  title: Text(
                    lesson.title,
                    style: TextStyle(
                      fontSize: 14,
                      decoration: lesson.isCompleted ? TextDecoration.lineThrough : null,
                      color: lesson.isCompleted
                          ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
                          : null,
                    ),
                  ),
                  trailing: Text(
                    lesson.duration,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                );
              }).toList(),
            ),
            crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }
}

extension _StringInitials on String {
  String get initials {
    final parts = trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty) return parts[0][0].toUpperCase();
    return '';
  }
}
