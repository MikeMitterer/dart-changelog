part of test;

testSimple() {
    final Logger logger = new Logger("test.testSimple");

    group('Test the test', () {

        test('> Test 1', () {
            expect(0, equals(0));
        });

    });
    // end "Test the test"
}

//------------------------------------------------------------------------------------------------
// Helper
//------------------------------------------------------------------------------------------------
