//
//  UserDefaultsIDStorage.swift
//  GPTExplorer
//
//  Created by James Rochabrun on 11/21/23.
//

import Foundation

struct UserDefaultsIDStorage<T: Codable & Equatable> {
   
   private let key: String
   private let userDefaults: UserDefaults
   
   init(key: String, userDefaults: UserDefaults = .standard) {
      self.key = key
      self.userDefaults = userDefaults
   }
   
   func add(id: T) {
      var ids = retrieve()
      if !ids.contains(id) {
         ids.append(id)
         save(ids: ids)
      }
   }
   
   func remove(id: T) {
      var ids = retrieve()
      ids.removeAll { $0 == id }
      save(ids: ids)
   }
   
   private func save(ids: [T]) {
      do {
         let encodedData = try JSONEncoder().encode(ids)
         userDefaults.set(encodedData, forKey: key)
      } catch {
         print("Failed to encode and save ids: \(error)")
      }
   }
   
   func retrieve() -> [T] {
      guard let data = userDefaults.data(forKey: key) else {
         return []
      }
      
      do {
         let ids = try JSONDecoder().decode([T].self, from: data)
         return ids
      } catch {
         print("Failed to decode ids: \(error)")
         return []
      }
   }
   
   func deleteAll() {
      userDefaults.removeObject(forKey: key)
   }
}
