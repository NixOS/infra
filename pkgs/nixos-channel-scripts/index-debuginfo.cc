#include <regex>

#include <nlohmann/json.hpp>

#include <nix/util/signals.hh>
#include <nix/util/thread-pool.hh>

#include <nix/store/nar-info.hh>
#include <nix/store/s3-binary-cache-store.hh>
#include <nix/store/sqlite.hh>

#include <nix/main/shared.hh>

// cache.nixos.org/debuginfo/<build-id>
//  => redirect to NAR

using namespace nix;

void mainWrapped(int argc, char * * argv)
{
    initNix();

    if (argc != 3) throw Error("usage: index-debuginfo DEBUG-DB BINARY-CACHE-URI");

    Path debugDbPath = argv[1];
    std::string binaryCacheUri = argv[2];

    if (hasSuffix(binaryCacheUri, "/")) binaryCacheUri.pop_back();
    auto binaryCache = openStore(binaryCacheUri).cast<S3BinaryCacheStore>();

    ThreadPool threadPool(25);

    auto doFile = [&](std::string build_id, std::string url, std::string filename) {
        checkInterrupt();

        nlohmann::json json;
        json["archive"] = url;
        json["member"] = filename;

        std::string key = "debuginfo/" + build_id;

        // FIXME: or should we overwrite? The previous link may point
        // to a GC'ed file, so overwriting might be useful...
        if (binaryCache->fileExists(key)) return;

        printError("redirecting ‘%s’ to ‘%s’", key, filename);

        binaryCache->upsertFile(key, json.dump(), "application/json");
    };

    auto db = SQLite(debugDbPath);

    auto stmt = SQLiteStmt(db, "select build_id, url, filename from DebugInfo;");
    auto query = stmt.use();

    while (query.next()) {
        threadPool.enqueue(std::bind(doFile, query.getStr(0), query.getStr(1), query.getStr(2)));
    }

    threadPool.process();
}

int main(int argc, char * * argv)
{
    return handleExceptions(argv[0], [&]() {
        mainWrapped(argc, argv);
    });
}
