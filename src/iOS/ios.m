//
//  ios.m

#include "angband.h"
#import <UIKit/UIKit.h>

void ios_init_file_paths(char *lib_path, char* path) {
    char *lib_tail;
    char* tail;

    /* Free the main path */
    string_free(ANGBAND_DIR);

    /* Free the sub-paths */
    string_free(ANGBAND_DIR_APEX);
    string_free(ANGBAND_DIR_BONE);
    string_free(ANGBAND_DIR_DATA);
    string_free(ANGBAND_DIR_EDIT);
    string_free(ANGBAND_DIR_FILE);
    string_free(ANGBAND_DIR_HELP);
    string_free(ANGBAND_DIR_INFO);
    string_free(ANGBAND_DIR_SAVE);
    string_free(ANGBAND_DIR_PREF);
    string_free(ANGBAND_DIR_USER);
    string_free(ANGBAND_DIR_XTRA);
    string_free(ANGBAND_DIR_SCRIPT);

    /*** Prepare the "path" ***/

    /* Hack -- save the main directory */
    ANGBAND_DIR = string_make(path);

    lib_tail = lib_path + strlen(lib_path);
    
    /* Prepare to append to the Base Path */
    tail = path + strlen(path);

    /*** Build the sub-directory names ***/

    /* Build a path name */
    strcpy(lib_tail, "edit");
    ANGBAND_DIR_EDIT = string_make(lib_path);

    /* Build a path name */
    strcpy(lib_tail, "pref");
    ANGBAND_DIR_PREF = string_make(lib_path);

    /* Build a path name */
    strcpy(lib_tail, "xtra");
    ANGBAND_DIR_XTRA = string_make(lib_path);

    /* Build a path name */
    strcpy(tail, "user");
    ANGBAND_DIR_USER = string_make(path);

    /* Build a path name */
    strcpy(tail, "data");
    ANGBAND_DIR_DATA = string_make(path);

    /* Build a path name */
    strcpy(tail, "apex");
    ANGBAND_DIR_APEX = string_make(path);

    /* Build a path name */
    strcpy(tail, "save");
    ANGBAND_DIR_SAVE = string_make(path);

    /* Build a path name */
    strcpy(tail, "script");
    ANGBAND_DIR_SCRIPT = string_make(path);
    
    [NSFileManager.defaultManager createDirectoryAtPath:@(ANGBAND_DIR_USER) withIntermediateDirectories:YES attributes:nil error:nil];
    [NSFileManager.defaultManager createDirectoryAtPath:@(ANGBAND_DIR_DATA) withIntermediateDirectories:YES attributes:nil error:nil];
    //Apex?
    [NSFileManager.defaultManager createDirectoryAtPath:@(ANGBAND_DIR_SAVE) withIntermediateDirectories:YES attributes:nil error:nil];
    //Script?
}

/**
 * Return the path for Angband's lib directory and bail if it isn't found. The
 * lib directory should be in the bundle's resources directory, since it's
 * copied when built.
 */
static NSString* get_lib_directory(void) {
    return [NSBundle.mainBundle pathForResource:@"sil.bundle/lib" ofType:nil];
}

/**
 * Return the path for the directory where Angband should look for its standard
 * user file tree.
 */
static NSString* get_support_directory(void) {
    NSString *documents = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];
    return [documents stringByAppendingPathComponent: @"sil"];
}

/**
 * Adjust directory paths as needed to correct for any differences needed by
 * Angband.  init_file_paths() currently requires that all paths provided have
 * a trailing slash and all other platforms honor this.
 *
 * \param originalPath The directory path to adjust.
 * \return A path suitable for Angband or nil if an error occurred.
 */
static NSString* AngbandCorrectedDirectoryPath(NSString *originalPath) {
    if ([originalPath length] == 0) {
        return nil;
    }

    if (![originalPath hasSuffix: @"/"]) {
        return [originalPath stringByAppendingString: @"/"];
    }

    return originalPath;
}

/**
 * Give Angband the base paths that should be used for the various directories
 * it needs. It will create any needed directories.
 */
static void prepare_paths_and_directories(void) {
    char libpath[PATH_MAX + 1] = "\0";
    NSString *libDirectoryPath =
        AngbandCorrectedDirectoryPath(get_lib_directory());
    [libDirectoryPath getFileSystemRepresentation: libpath maxLength: sizeof(libpath)];

    char basepath[PATH_MAX + 1] = "\0";
    NSString *angbandDocumentsPath =
        AngbandCorrectedDirectoryPath(get_support_directory());
    [angbandDocumentsPath getFileSystemRepresentation:basepath maxLength: sizeof(basepath)];

    ios_init_file_paths(libpath, basepath);
}

/**
 * Load preferences from preferences file for current host+current user+
 * current application.
 */
static void load_prefs(void) {
    use_transparency = TRUE;
    ANGBAND_GRAF = "new";
}

static BOOL engine_started;
//extern errr term_xtra_ios(int n, int v);

void start_sil_engine(void) {
    if (engine_started) {
        return;
    }
    
    arg_sound = TRUE;
    
    /* Initialize file paths */
    prepare_paths_and_directories();

    /* Note the "system" */
    ANGBAND_SYS = "mac"; //reuse graf-mac.prf & pref-mac.prf

    /* Load preferences */
    load_prefs();

    /* Prepare the windows */
    //Simulate a main window
    struct term *t = ZNEW(term);
    term_init(t, 80, 25, 256);
    //t->xtra_hook = term_xtra_ios;
    Term_activate(t);
    term_screen = t;

    init_angband();
        
    engine_started = true;
}

UIColor *color_for_index(int idx) {
    CGFloat rv = angband_color_table[idx][1];
    CGFloat gv = angband_color_table[idx][2];
    CGFloat bv = angband_color_table[idx][3];
    return [UIColor colorWithRed:rv/255.0 green:gv/255.0 blue:bv/255.0 alpha:1];
}

NSString *skill_equation(NSInteger index) {
    return [NSString stringWithFormat:@"%3d = %2d %+3d %+3d %+3d ",
            p_ptr->skill_use[index],
            p_ptr->skill_base[index],
            p_ptr->skill_stat_mod[index],
            p_ptr->skill_equip_mod[index],
            p_ptr->skill_misc_mod[index]];
}

NSAttributedString *messages(int limit) {
    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] init];
    for (int i = 0; i < MIN(message_num(), limit); ++i) {
        cptr message = message_str(i);
        if (!message) {
            break;
        }
        UIColor *typeColor = color_for_index(message_color(i));
        [attr appendAttributedString:[[NSAttributedString alloc] initWithString:@(message) attributes:@{
            NSBackgroundColorAttributeName: UIColor.blackColor,
            NSForegroundColorAttributeName: typeColor
        }]];
        [attr appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
    }
    return attr;
}
