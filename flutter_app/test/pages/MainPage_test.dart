import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutterapp/changelog/ChangelogService.dart';
import 'package:flutterapp/pages/MainPage.dart';
import 'package:flutterapp/widgets/ChangelogDialogFactory.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockChangelog extends Mock implements ChangelogService {}

class MockChangelogDialog extends Mock implements ChangelogDialogFactory {}

void main() {
  group('changelog modal', () {
    testWidgets(
        "should show changelog dialog when user has not seen the latest changelog",
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      when(ChangelogService.getLatestVersion()).thenReturn('0.0.0');

      when(ChangelogDialogFactory.getChangelogDialog(context));
      await tester.pumpWidget(MainPage(title: 'NPH'));
      expect(find.byWidget("Sign in with Twitter"), findsOneWidget);
      expect(find.text("Sign in with Facebook"), findsOneWidget);
      expect(find.text("Sign in with Reddit"), findsOneWidget);
    });
  });

  testWidgets("login page test", (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
        home: LoginSignUpPage(
      onSignedIn: () => {},
    )));
    expect(find.text("Create an account"), findsOneWidget);
    await tester.tap(find.byType(FlatButton));
    await tester.pump();
    expect(find.text("Have an account? Sign in"), findsOneWidget);
  });

  testWidgets("reddit post like test", (WidgetTester tester) async {
    Post post = new Post("test", "me", "hey", DateTime.now(), false,
        "google.com", "google.com", "b8mouf", PostSource.reddit, "", "", "",
        imageUrl: "");
    await tester.pumpWidget(MaterialApp(home: new PostItem(post: post)));
    expect(find.text("test"), findsOneWidget);
    expect(
        find.widgetWithIcon(FlatButton, Icons.favorite_border), findsOneWidget);
    await tester.tap(find.widgetWithIcon(FlatButton, Icons.favorite_border));
    await tester.pump();
    await tester.pumpWidget(MaterialApp(home: new PostItem(post: post)));
    expect(find.byIcon(Icons.favorite), findsOneWidget);
  });

  //Sprint 3 test cases
  testWidgets("add filter test", (WidgetTester tester) async {
    List<String> settings = ["nintendo", "reggie", "switch"];
    await tester.pumpWidget(MaterialApp(
        home: ManageFeed(
      uid: "Rk7RdNGX8ic5YZxRuScAdVr7CnJ2",
      feedName: "Nintendo",
      settings: settings,
    )));
    Finder finder = find.widgetWithIcon(IconButton, Icons.add);
    expect(finder, findsOneWidget);
    await tester.tap(finder);
    await tester.pump();
    finder = find.widgetWithText(TextFormField, "");
    expect(finder, findsOneWidget);
  });

  testWidgets("remove filter test", (WidgetTester tester) async {
    List<String> settings = ["nintendo", "reggie", "switch"];
    await tester.pumpWidget(MaterialApp(
        home: ManageFeed(
      uid: "Rk7RdNGX8ic5YZxRuScAdVr7CnJ2",
      feedName: "Nintendo",
      settings: settings,
    )));
    Finder finder = find.widgetWithText(TextFormField, "nintendo");
    expect(finder, findsOneWidget);
    expect(find.widgetWithText(Dismissible, "nintendo"), findsOneWidget);
    await tester.drag(
        find.widgetWithText(Dismissible, "nintendo"), Offset(-400, 0));
    await tester.pumpAndSettle();
    finder = find.widgetWithText(TextFormField, "nintendo");
    expect(finder, findsNothing);
  });
}
