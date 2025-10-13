#include <gtest/gtest.h>
#include "../math_operations.h"

// Test suite: MathTests
TEST(MathTests, BasicAdditionTest) {
	EXPECT_EQ(add(2, 3), 5);
}

TEST(MathTests, NegativeNumbersTest) {
	EXPECT_EQ(add(-2, -3), -5);
}

TEST(MathTests, ZeroTest) {
	EXPECT_EQ(add(0, 0), 0);
}

int main(int argc, char **argv) {
	::testing::InitGoogleTest(&argc, argv);
	return RUN_ALL_TESTS();
}

