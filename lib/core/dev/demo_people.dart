/// Deterministic pool of demo users for the marketing seeder. Pure data (no
/// Firebase/DB imports). 50 varied Vietnamese profiles with scattered
/// streak/xp/wake so the leaderboard, feed and friends list look real.
/// Regenerating is stable (index-based formulas, no randomness) → re-seeding
/// is idempotent.
class DemoPerson {
  const DemoPerson({
    required this.uid,
    required this.username,
    required this.name,
    required this.bio,
    required this.streak,
    required this.longest,
    required this.xp,
    required this.level,
    required this.wake,
    required this.photos,
    required this.coins,
    required this.avatar,
  });

  final String uid;
  final String username;
  final String name;
  final String bio;
  final int streak;
  final int longest;
  final int xp;
  final int level;
  final double wake;
  final int photos;
  final int coins;
  final String avatar;
}

const _families = [
  'Nguyễn', 'Trần', 'Lê', 'Phạm', 'Hoàng', 'Phan', 'Vũ', 'Đặng', 'Bùi', 'Đỗ',
  'Hồ', 'Ngô', 'Dương', 'Lý', 'Mai', 'Đinh',
];

/// (display, ascii-slug) given names — slug feeds username/uid (ascii only, so
/// the username prefix-search query works).
const _given = <List<String>>[
  ['An', 'an'], ['Bình', 'binh'], ['Chi', 'chi'], ['Dũng', 'dung'],
  ['Duy', 'duy'], ['Giang', 'giang'], ['Hà', 'ha'], ['Hải', 'hai'],
  ['Hằng', 'hang'], ['Hiếu', 'hieu'], ['Hoa', 'hoa'], ['Huy', 'huy'],
  ['Khoa', 'khoa'], ['Lan', 'lan'], ['Linh', 'linh'], ['Long', 'long'],
  ['Mai', 'mai'], ['Minh', 'minh'], ['Nam', 'nam'], ['Nga', 'nga'],
  ['Ngân', 'ngan'], ['Nhung', 'nhung'], ['Phong', 'phong'], ['Phúc', 'phuc'],
  ['Phương', 'phuong'], ['Quân', 'quan'], ['Quỳnh', 'quynh'], ['Sơn', 'son'],
  ['Tâm', 'tam'], ['Thảo', 'thao'], ['Thu', 'thu'], ['Trang', 'trang'],
  ['Trung', 'trung'], ['Tú', 'tu'], ['Tuấn', 'tuan'], ['Vân', 'van'],
  ['Việt', 'viet'], ['Vy', 'vy'], ['Yến', 'yen'], ['Đạt', 'dat'],
];

const _bios = [
  'Chăm chỉ mỗi ngày 💪', 'Dậy sớm cùng nhau ☀️', 'Không snooze!',
  'Yêu buổi sáng', 'Cà phê là chân ái ☕', 'Cố gắng lên!', 'Sống healthy 🥗',
  '5 giờ sáng là chân lý', 'Morning person 🌅', 'Kỷ luật tạo nên tự do', '',
  'Chạy bộ mỗi sáng 🏃',
];

/// Captions for the seeded morning-photo feed posts.
const demoCaptions = [
  'Chào buổi sáng! Dậy lúc 5:30 ☀️',
  'Cà phê và bình minh ☕',
  'Chạy bộ 5km xong, sảng khoái 🏃',
  'Thiền 10 phút đầu ngày 🧘',
  'Không snooze hôm nay 💪',
  'Trời đẹp quá, dậy sớm thật đáng!',
  'Bữa sáng healthy 🥗',
  'Ngày mới năng lượng ⚡',
  'Đọc sách 20 phút sáng nay 📚',
  'Tập yoga đón nắng 🌅',
];

/// Short comment texts for the seeded feed.
const demoComments = [
  'Đỉnh quá! 🔥',
  'Ghen tị ghê 😍',
  'Nhìn ngon thế 😋',
  'Quá xịn 👏',
  'Cùng cố gắng nhé!',
  'Sáng nào cũng đều ghê 💪',
];

const demoReactEmojis = ['❤️', '🔥', '💪', '😍', '😮', '😂'];

/// Builds the 50-person demo pool. Deterministic → stable ids across re-seeds.
List<DemoPerson> buildDemoPeople() {
  final people = <DemoPerson>[];
  for (var i = 0; i < 50; i++) {
    final g = _given[i % _given.length];
    final fam = _families[(i * 7) % _families.length];
    final streak = (i * 37 + 11) % 43; // 0..42, scattered
    final longest = streak + ((i * 13 + 7) % 16); // >= streak
    final xp = streak * 70 + (i * 53) % 300 + 40;
    final wake = (0.45 + (streak / 42) * 0.5).clamp(0.0, 0.99).toDouble();
    people.add(DemoPerson(
      uid: 'seed_${g[1]}$i',
      username: '${g[1]}$i',
      name: '$fam ${g[0]}',
      bio: _bios[i % _bios.length],
      streak: streak,
      longest: longest,
      xp: xp,
      level: xp ~/ 500 + 1,
      wake: double.parse(wake.toStringAsFixed(2)),
      photos: streak * 3 + (i * 7) % 40,
      coins: xp ~/ 3 + (i * 11) % 200,
      avatar: 'https://i.pravatar.cc/150?img=${(i % 70) + 1}',
    ));
  }
  return people;
}
