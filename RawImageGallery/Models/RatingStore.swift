import Foundation
import SQLite3

/// Manages persistent storage of image ratings using SQLite.
///
/// Ratings are stored in a local database and synchronized with an in-memory cache.
class RatingStore: ObservableObject {
    @Published var ratings: [String: Int] = [:]
    
    private var db: OpaquePointer?
    private let dbPath: String
    
    init() {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("RawImageGallery", isDirectory: true)
        
        try? fileManager.createDirectory(at: appDir, withIntermediateDirectories: true)
        
        dbPath = appDir.appendingPathComponent("ratings.db").path
        
        openDatabase()
        createTable()
        loadAllRatings()
    }
    
    deinit {
        sqlite3_close(db)
    }
    
    // MARK: - Public Methods
    
    /// Gets the rating for a specific image.
    ///
    /// - Parameter url: The image file URL.
    /// - Returns: The rating (0-5), or 0 if not rated.
    func getRating(for url: URL) -> Int {
        ratings[url.path] ?? 0
    }
    
    /// Sets the rating for a specific image.
    ///
    /// - Parameters:
    ///   - rating: The rating value (0-5).
    ///   - url: The image file URL.
    func setRating(_ rating: Int, for url: URL) {
        let path = url.path
        ratings[path] = rating
        
        let upsertQuery = """
        INSERT INTO ratings (file_path, rating, updated_at)
        VALUES (?, ?, CURRENT_TIMESTAMP)
        ON CONFLICT(file_path) DO UPDATE SET
            rating = excluded.rating,
            updated_at = CURRENT_TIMESTAMP;
        """
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, upsertQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (path as NSString).utf8String, -1, nil)
            sqlite3_bind_int(statement, 2, Int32(rating))
            
            if sqlite3_step(statement) != SQLITE_DONE {
                print("Error saving rating")
            }
        }
        sqlite3_finalize(statement)
    }
    
    /// Deletes the rating for a specific image.
    ///
    /// - Parameter url: The image file URL.
    func deleteRating(for url: URL) {
        let path = url.path
        ratings.removeValue(forKey: path)
        
        let deleteQuery = "DELETE FROM ratings WHERE file_path = ?;"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, deleteQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (path as NSString).utf8String, -1, nil)
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
    }
    
    /// Clears all ratings from the database.
    func clearAllRatings() {
        ratings.removeAll()
        
        let deleteQuery = "DELETE FROM ratings;"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, deleteQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
    }
    
    // MARK: - Private Methods
    
    private func openDatabase() {
        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            print("Error opening database")
        }
    }
    
    private func createTable() {
        let createTableQuery = """
        CREATE TABLE IF NOT EXISTS ratings (
            file_path TEXT PRIMARY KEY,
            rating INTEGER NOT NULL,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        """
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, createTableQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                print("Ratings table created successfully")
            }
        }
        sqlite3_finalize(statement)
    }
    
    private func loadAllRatings() {
        let query = "SELECT file_path, rating FROM ratings;"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let path = String(cString: sqlite3_column_text(statement, 0))
                let rating = Int(sqlite3_column_int(statement, 1))
                ratings[path] = rating
            }
        }
        sqlite3_finalize(statement)
    }
}
