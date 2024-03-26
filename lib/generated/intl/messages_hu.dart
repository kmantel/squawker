// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a hu locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'hu';

  static String m0(name) =>
      "Biztos benne, hogy letörli a ${name} feliratkozási csoportot?";

  static String m1(fileName) => "Adatok exportálva ${fileName} néven";

  static String m2(fullPath) => "Adatok exportálva a ${fullPath} mappába";

  static String m8(date) => "Csatlakozva ${date}";

  static String m15(filePath) =>
      "A fájl nem létezik. Győződjön meg róla, hogy a ${filePath} helyen található";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "about": MessageLookupByLibrary.simpleMessage("Névjegy"),
        "add_to_group":
            MessageLookupByLibrary.simpleMessage("Hozzáadás csoporthoz"),
        "all": MessageLookupByLibrary.simpleMessage("Mind"),
        "all_the_great_software_used_by_fritter":
            MessageLookupByLibrary.simpleMessage(
                "Az összes csodás szoftver a Squawker szolgálatában"),
        "app_info": MessageLookupByLibrary.simpleMessage("App Infó"),
        "are_you_sure": MessageLookupByLibrary.simpleMessage("Biztos benne?"),
        "are_you_sure_you_want_to_delete_the_subscription_group_name_of_group":
            m0,
        "beta": MessageLookupByLibrary.simpleMessage("BÉTA"),
        "cancel": MessageLookupByLibrary.simpleMessage("Mégse"),
        "close": MessageLookupByLibrary.simpleMessage("Bezár"),
        "contribute": MessageLookupByLibrary.simpleMessage("Hozzájárulás"),
        "copied_address_to_clipboard":
            MessageLookupByLibrary.simpleMessage("Cím másolva a vágólapra"),
        "copied_version_to_clipboard":
            MessageLookupByLibrary.simpleMessage("Verzió a vágólapra másolva"),
        "could_not_find_any_tweets_by_this_user":
            MessageLookupByLibrary.simpleMessage(
                "Nem találhatóak tweet-ek ennél a felhasználónál!"),
        "could_not_find_any_tweets_from_the_last_7_days":
            MessageLookupByLibrary.simpleMessage(
                "Nem található egy tweet sem az elmúlt 7 napból!"),
        "dark": MessageLookupByLibrary.simpleMessage("Sötét"),
        "data": MessageLookupByLibrary.simpleMessage("Adat"),
        "data_exported_to_fileName": m1,
        "data_exported_to_fullPath": m2,
        "data_imported_successfully": MessageLookupByLibrary.simpleMessage(
            "Adatok sikeresen importálásra kerültek"),
        "default_tab": MessageLookupByLibrary.simpleMessage("Alap fül"),
        "delete": MessageLookupByLibrary.simpleMessage("Törlés"),
        "disabled": MessageLookupByLibrary.simpleMessage("Kikapcsolva"),
        "donate": MessageLookupByLibrary.simpleMessage("Támogatás"),
        "enable_": MessageLookupByLibrary.simpleMessage("Bekapcsolás ?"),
        "export": MessageLookupByLibrary.simpleMessage("Exportálás"),
        "export_guest_accounts": MessageLookupByLibrary.simpleMessage(
            "Exportálni akarja a vendég fiókokat?"),
        "export_settings":
            MessageLookupByLibrary.simpleMessage("Beállítások exportálása?"),
        "export_subscription_group_members":
            MessageLookupByLibrary.simpleMessage(
                "Exportálni akarja a feliratkozási csoport tagjait?"),
        "export_subscription_groups": MessageLookupByLibrary.simpleMessage(
            "Exportálni akarja a feliratkozási csoportokat?"),
        "export_subscriptions":
            MessageLookupByLibrary.simpleMessage("Feliratkozások exportálása?"),
        "export_tweets": MessageLookupByLibrary.simpleMessage(
            "Exportálni kívánja a tweet-eket?"),
        "export_your_data":
            MessageLookupByLibrary.simpleMessage("Adatai exportálása"),
        "feed": MessageLookupByLibrary.simpleMessage("Hírfolyam"),
        "filters": MessageLookupByLibrary.simpleMessage("Szűrők"),
        "followers": MessageLookupByLibrary.simpleMessage("Követők"),
        "following": MessageLookupByLibrary.simpleMessage("Bekövetve"),
        "fritter": MessageLookupByLibrary.simpleMessage("Squawker"),
        "general": MessageLookupByLibrary.simpleMessage("Általános"),
        "help_make_fritter_even_better":
            MessageLookupByLibrary.simpleMessage("Tedd még jobbá a Squawker-t"),
        "help_support_fritters_future": MessageLookupByLibrary.simpleMessage(
            "Támogassa a Squawker jövőjét"),
        "import": MessageLookupByLibrary.simpleMessage("Importálás"),
        "import_data_from_another_device": MessageLookupByLibrary.simpleMessage(
            "Adat importálása egy másik eszközről"),
        "import_subscriptions":
            MessageLookupByLibrary.simpleMessage("Feliratkozások Importálása"),
        "include_replies":
            MessageLookupByLibrary.simpleMessage("Válaszok mutatása"),
        "include_retweets":
            MessageLookupByLibrary.simpleMessage("Retweet-ek mutatása"),
        "joined": m8,
        "large": MessageLookupByLibrary.simpleMessage("Nagy"),
        "legacy_android_import":
            MessageLookupByLibrary.simpleMessage("Régi típusú Android import"),
        "let_the_developers_know_if_something_is_broken":
            MessageLookupByLibrary.simpleMessage(
                "Tudassa a fejlesztőkkel ha valami hiba jelentkezik"),
        "licenses": MessageLookupByLibrary.simpleMessage("Licenszek"),
        "light": MessageLookupByLibrary.simpleMessage("Világos"),
        "live": MessageLookupByLibrary.simpleMessage("ÉLŐ"),
        "logging": MessageLookupByLibrary.simpleMessage("Naplózás"),
        "material_3": MessageLookupByLibrary.simpleMessage("Material 3?"),
        "media": MessageLookupByLibrary.simpleMessage("Média"),
        "media_size": MessageLookupByLibrary.simpleMessage("Média méret"),
        "medium": MessageLookupByLibrary.simpleMessage("Közepes"),
        "name": MessageLookupByLibrary.simpleMessage("Név"),
        "newTrans": MessageLookupByLibrary.simpleMessage("Új"),
        "no": MessageLookupByLibrary.simpleMessage("Nem"),
        "no_results": MessageLookupByLibrary.simpleMessage("Nincs eredmény"),
        "no_results_for": MessageLookupByLibrary.simpleMessage(
            "Nincs találat a következőre:"),
        "note_due_to_a_twitter_limitation_not_all_tweets_may_be_included":
            MessageLookupByLibrary.simpleMessage(
                "Megjegyzés: A Twitter/X limitációk miatt nem minden tweet jelenik meg"),
        "ok": MessageLookupByLibrary.simpleMessage("Rendben"),
        "pick_a_color":
            MessageLookupByLibrary.simpleMessage("Válasszon egy színt!"),
        "pick_an_icon":
            MessageLookupByLibrary.simpleMessage("Válasszon egy ikont!"),
        "please_enter_a_name":
            MessageLookupByLibrary.simpleMessage("Kérem adjon meg egy nevet"),
        "please_make_sure_the_data_you_wish_to_import_is_located_there_then_press_the_import_button_below":
            MessageLookupByLibrary.simpleMessage(
                "Győződjön meg róla, hogy a kívánt fájl rendelkezésre áll, majd nyomjon rá az importálásra."),
        "prefix": MessageLookupByLibrary.simpleMessage("előtag"),
        "released_under_the_mit_license": MessageLookupByLibrary.simpleMessage(
            "Megjelenés az MIT Licensz alatt"),
        "report_a_bug": MessageLookupByLibrary.simpleMessage("Bug jelentése"),
        "reporting_an_error":
            MessageLookupByLibrary.simpleMessage("Hiba bejelentése"),
        "save_bandwidth_using_smaller_images":
            MessageLookupByLibrary.simpleMessage(
                "Sávszél megtakarítás kisebb képekkel"),
        "saved": MessageLookupByLibrary.simpleMessage("Mentett"),
        "search": MessageLookupByLibrary.simpleMessage("Keresés"),
        "select": MessageLookupByLibrary.simpleMessage("Kiválasztás"),
        "send": MessageLookupByLibrary.simpleMessage("Küldés"),
        "settings": MessageLookupByLibrary.simpleMessage("Beállítások"),
        "small": MessageLookupByLibrary.simpleMessage("Kicsi"),
        "something_just_went_wrong_in_fritter_and_an_error_report_has_been_generated":
            MessageLookupByLibrary.simpleMessage(
                "Valami félresiklott a Squawker-ben, és generálódott egy hiba riport. Lehetősége van a riportot elküldeni a fejlesztőknek, hogy megkezdődjön a hibajavítás."),
        "subscribe": MessageLookupByLibrary.simpleMessage("Feliratkozás"),
        "subscriptions": MessageLookupByLibrary.simpleMessage("Feliratkozások"),
        "system": MessageLookupByLibrary.simpleMessage("Rendszer"),
        "thanks_for_helping_fritter": MessageLookupByLibrary.simpleMessage(
            "Köszönjük, hogy segít a Squawker-nek! 💖"),
        "the_file_does_not_exist_please_ensure_it_is_located_at_file_path": m15,
        "theme": MessageLookupByLibrary.simpleMessage("Téma"),
        "theme_mode": MessageLookupByLibrary.simpleMessage("Téma Mód"),
        "this_group_contains_no_subscriptions":
            MessageLookupByLibrary.simpleMessage(
                "Ez a csoport nem tartalmaz feliratkozásokat!"),
        "this_user_does_not_follow_anyone":
            MessageLookupByLibrary.simpleMessage(
                "Ez a felhasználó nem követ senkit!"),
        "this_user_does_not_have_anyone_following_them":
            MessageLookupByLibrary.simpleMessage(
                "Ezt a felhasználót nem követi senki!"),
        "thumbnail": MessageLookupByLibrary.simpleMessage("Miniatűr"),
        "to_import_subscriptions_from_an_existing_twitter_account_enter_your_username_below":
            MessageLookupByLibrary.simpleMessage(
                "Már létező Twitter/X fiókból való feliratkozások importálásához adja meg a felhasználónevét."),
        "toggle_all":
            MessageLookupByLibrary.simpleMessage("Mind ki/be jelölése"),
        "trending": MessageLookupByLibrary.simpleMessage("Felkapott"),
        "true_black": MessageLookupByLibrary.simpleMessage("Teljesen Fekete?"),
        "tweets": MessageLookupByLibrary.simpleMessage("Teweet-ek"),
        "tweets_and_replies":
            MessageLookupByLibrary.simpleMessage("Tweet-ek & válaszok"),
        "unable_to_find_your_saved_tweets":
            MessageLookupByLibrary.simpleMessage(
                "Nem találhatóak mentett tweet-ek."),
        "unable_to_load_subscription_groups":
            MessageLookupByLibrary.simpleMessage(
                "Nem sikerült betölteni a feliratkozási csoportokat"),
        "unable_to_load_the_group":
            MessageLookupByLibrary.simpleMessage("A csoport nem tölthető be"),
        "unable_to_load_the_group_settings":
            MessageLookupByLibrary.simpleMessage(
                "A csoport beállítások nem tölthetőek be"),
        "unable_to_load_the_list_of_follows":
            MessageLookupByLibrary.simpleMessage(
                "Nem tölthető be a követők listája"),
        "unable_to_load_the_next_page_of_follows":
            MessageLookupByLibrary.simpleMessage(
                "Nem tölthető be a követők következő oldala"),
        "unable_to_load_the_next_page_of_replies":
            MessageLookupByLibrary.simpleMessage(
                "Nem tölthető be a következő oldalnyi válasz"),
        "unable_to_load_the_next_page_of_tweets":
            MessageLookupByLibrary.simpleMessage(
                "Nem sikerült a következő oldalnyi tweet betöltése"),
        "unable_to_load_the_profile":
            MessageLookupByLibrary.simpleMessage("Profil nem tölthető be"),
        "unable_to_load_the_search_results":
            MessageLookupByLibrary.simpleMessage(
                "Keresési eredmények nem tölthetőek be."),
        "unable_to_load_the_tweet": MessageLookupByLibrary.simpleMessage(
            "Nem sikerült betölteni a tweet-et"),
        "unable_to_load_the_tweets":
            MessageLookupByLibrary.simpleMessage("Tweet-ek nem tölthetőek be"),
        "unable_to_load_the_tweets_for_the_feed":
            MessageLookupByLibrary.simpleMessage(
                "Nem sikerült betölteni a tweet-eket a hírfolyamon"),
        "unsubscribe": MessageLookupByLibrary.simpleMessage("Leiratkozás"),
        "use_true_black_for_the_dark_mode_theme":
            MessageLookupByLibrary.simpleMessage(
                "Használjon teljesen feketét a sötét módban"),
        "version": MessageLookupByLibrary.simpleMessage("Verzió"),
        "whether_errors_should_be_reported_to_":
            MessageLookupByLibrary.simpleMessage(
                "Kell e a hibát bejelenteni az illetékes számára "),
        "which_tab_is_shown_when_the_app_opens":
            MessageLookupByLibrary.simpleMessage(
                "Melyik fül nyílik meg az app megnyitásakor"),
        "would_you_like_to_enable_automatic_error_reporting":
            MessageLookupByLibrary.simpleMessage(
                "Be akarja kapcsolni az automata hiba jelentés küldést?"),
        "yes": MessageLookupByLibrary.simpleMessage("Igen"),
        "yes_please": MessageLookupByLibrary.simpleMessage("Igen, kérem"),
        "you_have_not_saved_any_tweets_yet":
            MessageLookupByLibrary.simpleMessage(
                "Nem mentett el eddig tweet-eket!"),
        "your_report_will_be_sent_to_fritter__project":
            MessageLookupByLibrary.simpleMessage(
                "A riport küldésre került a Squawker  projektje felé. Az adatvédelmi politikát itt találja:")
      };
}
