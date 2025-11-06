/* File: ios.h */

#import <UIKit/UIKit.h>

void start_sil_engine(void);

UIColor *color_for_index(int idx);
UIImage *image_for_a_c(int a, int c);

NSString *skill_equation(NSInteger index);

NSAttributedString *messages(int limit);
