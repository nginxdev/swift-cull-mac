import Foundation
import SQLite3

/// Manages persistent storage of image categories using SQLite.
///
/// Categories are stored as JSON arrays in the database and synchronized with an in-memory cache.
class CategoryStore: ObservableObject {
    @Published var categories: [String: Set<Int>] = [:]
    
    private var db: OpaquePointer?
    private let dbPath: String
    private var isInitialized = false
    
    static let categoryColors: [String] = ["Red", "Blue", "Green", "Yellow", "Purple"]
    
    init() {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("RawImageGallery", isDirectory: true)
        
        try? fileManager.createDirectory(at: appDir, withIntermediateDirectories: true)
        
        dbPath = appDir.appendingPathComponent("ratings.db").path
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.initializeDatabase()
        }
    }
    
    deinit {
        sqlite3_close(db)
    }
    
    // MARK: - Public Methods
    
    /// Gets the categories for a specific image.
    ///
    /// - Parameter url: The image file URL.
    /// - Returns: A set of category indices (0-4).
    func getCategories(for url: URL) -> Set<Int> {
        categories[url.path] ?? []
    }
    
    /// Sets the categories for a specific image.
    ///
    /// - Parameters:
    ///   - categories: A set of category indices (0-4).
    ///   - url: The image file URL.
    func setCategories(_ categories: Set<Int>, for url: URL) {
        guard isInitialized else { return }
        
        let path = url.path
        self.categories[path] = categories
        
        guard let jsonData = try? JSONEncoder().encode(Array(categories)),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return
        }
        
        let upsertQuery = """
        INSERT INTO categories (file_path, category_json, updated_at)
        VALUES (?, ?, CURRENT_TIMESTAMP)
        ON CONFLICT(file_path) DO UPDATE SET
            category_json = excluded.category_json,
            updated_at = CURRENT_TIMESTAMP;
        """
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, upsertQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (path as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (jsonString as NSString).utf8String, -1, nil)
            
            if sqlite3_step(statement) != SQLITE_DONE {
                print("Error saving categories")
            }
        }
        sqlite3_finalize(statement)
    }
    
    /// Deletes the categories for a specific image.
    ///
    /// - Parameter url: The image file URL.
    func deleteCategories(for url: URL) {
        guard isInitialized else { return }
        
        let path = url.path
        categories.removeValue(forKey: path)
        
        let deleteQuery = "DELETE FROM categories WHERE file_path = ?;"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, deleteQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (path as NSString).utf8String, -1, nil)
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
    }
    
    /// Clears all categories from the database.
    func clearAllCategories() {
        guard isInitialized else { return }
        
        categories.removeAll()
        
        let deleteQuery = "DELETE FROM categories;"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, deleteQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
    }
    
    // MARK: - Private Methods
    
    private func initializeDatabase() {
        openDatabase()
        createTable()
        loadAllCategories()
        isInitialized = true
    }
    
    private func openDatabase() {
        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            print("CategoryStore: Error opening database")
        }
    }
    
    private func createTable() {
        let createTableQuery = """
        CREATE TABLE IF NOT EXISTS categories (
            file_path TEXT PRIMARY KEY,
            category_json TEXT NOT NULL,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
        """
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, createTableQuery, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                print("CategoryStore: Categories table created successfully")
            }
        }
        sqlite3_finalize(statement)
    }
    
    private func loadAllCategories() {
        let query = "SELECT file_path, category_json FROM categories;"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let path = String(cString: sqlite3_column_text(statement, 0))
                let jsonString = String(cString: sqlite3_column_text(statement, 1))
                
                if let jsonData = jsonString.data(using: .utf8),
                   let categoryArray = try? JSONDecoder().decode([Int].self, from: jsonData) {
                    categories[path] = Set(categoryArray)
                }
            }
        }
        sqlite3_finalize(statement)
    }
}
