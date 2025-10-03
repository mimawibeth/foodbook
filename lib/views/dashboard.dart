import 'package:cce106_flutter_project/views/create_recipe.dart';
import 'package:flutter/material.dart';
import 'discover.dart';
import 'my_recipes.dart';
import 'favorites.dart';
import 'profile.dart';
import '../widgets/recipe_card.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardHome(),
    const MyRecipes(),
    const Favorites(),
    const Profile(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      backgroundColor: const Color(0xFFFAFAFA),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          selectedItemColor: const Color(0xFFD72638),
          unselectedItemColor: const Color(0xFF1C1C1C),
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.restaurant),
              label: 'Discover',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book),
              label: 'My Recipes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite),
              label: 'Favorites',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class DashboardHome extends StatelessWidget {
  const DashboardHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFFD72638),
        title: const Text(
          "FoodBook",
          style: TextStyle(
            color: Color(0xFFFAFAFA),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.search, color: Color(0xFFFAFAFA)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Post bar
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateRecipePage(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              color: Colors.white,
              child: Row(
                children: const [
                  Icon(
                    Icons.account_circle,
                    size: 32,
                    color: Color(0xFF1C1C1C),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Want to share your recipe?",
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Strong line below for separation
          Container(
            height: 2,
            color: Color(0xFFF2A541), // ✅ Mustard Yellow
            margin: const EdgeInsets.symmetric(vertical: 2),
          ),

          // Tabs (Home, Breakfast, Lunch, Dinner)
          Container(color: Colors.white, child: const TabBarSection()),

          // Recipe List
          Expanded(
            child: ListView(
              children: const [
                RecipeCard(
                  username: "Rodrigo Binangkal",
                  recipeTitle: "Binangkal Recipe",
                  description:
                      "Dessert\nIngredients:\n1 1/2 cup all purpose flour\n1/3 cup sugar\n1 tbsp melted butter\n1/4 cup evaporated milk",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TabBarSection extends StatelessWidget {
  const TabBarSection({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: const [
          TabBar(
            labelColor: Color(0xFFD72638),
            unselectedLabelColor: Color(0xFF1C1C1C),
            indicatorColor: Color(0xFFF2A541),
            tabs: [
              Tab(text: "Home"),
              Tab(text: "Breakfast"),
              Tab(text: "Lunch"),
              Tab(text: "Dinner"),
            ],
          ),
        ],
      ),
    );
  }
}
