//The Gift List Organizer is a user-friendly app designed to help you manage your gift-giving effortlessly. Keep track of gifts for various occasions with details like recipient, category, price, and status. Easily add, edit, and delete gifts, recipients, and categories while enjoying features like search and sort for quick access. With its intuitive interface and persistent storage, this app ensures you never forget a gift again. Perfect for busy shoppers, event planners, and anyone who loves giving thoughtful presents!

import SwiftUI

// Models to represent entities
struct Gift: Identifiable, Codable {
    var id = UUID()
    var name: String
    var description: String
    var status: String // "Pending" or "Purchased"
    var price: Double
    var store: String
    var purchaseDate: Date
    var recipient: Recipient
    var category: Category
}

struct Recipient: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
}

struct Category: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
}

// ViewModel to handle data
class GiftViewModel: ObservableObject {
    @Published var gifts: [Gift] {
        didSet {
            saveGifts()
        }
    }
    
    @Published var recipients: [Recipient] {
        didSet {
            saveRecipients()
        }
    }
    
    @Published var categories: [Category] {
        didSet {
            saveCategories()
        }
    }
    
    init() {
        self.gifts = UserDefaults.standard.loadGifts()
        self.recipients = UserDefaults.standard.loadRecipients()
        self.categories = UserDefaults.standard.loadCategories()
    }
    
    // CRUD for gifts
    func addGift(_ gift: Gift) {
        gifts.append(gift)
    }
    
    func deleteGift(at offsets: IndexSet) {
        gifts.remove(atOffsets: offsets)
    }
    
    func updateGift(_ gift: Gift) {
        if let index = gifts.firstIndex(where: { $0.id == gift.id }) {
            gifts[index] = gift
        }
    }
    
    // CRUD for recipients
    func addRecipient(_ recipient: Recipient) {
        recipients.append(recipient)
    }
    
    func deleteRecipient(at offsets: IndexSet) {
        recipients.remove(atOffsets: offsets)
    }
    
    // CRUD for categories
    func addCategory(_ category: Category) {
        categories.append(category)
    }
    
    func deleteCategory(at offsets: IndexSet) {
        categories.remove(atOffsets: offsets)
    }
    
    // Save data to UserDefaults
    private func saveGifts() {
        if let encoded = try? JSONEncoder().encode(gifts) {
            UserDefaults.standard.set(encoded, forKey: "gifts")
        }
    }
    
    private func saveRecipients() {
        if let encoded = try? JSONEncoder().encode(recipients) {
            UserDefaults.standard.set(encoded, forKey: "recipients")
        }
    }
    
    private func saveCategories() {
        if let encoded = try? JSONEncoder().encode(categories) {
            UserDefaults.standard.set(encoded, forKey: "categories")
        }
    }
}

// UserDefaults extensions for loading entities
extension UserDefaults {
    func loadGifts() -> [Gift] {
        if let data = data(forKey: "gifts"),
           let decoded = try? JSONDecoder().decode([Gift].self, from: data) {
            return decoded
        }
        return []
    }
    
    func loadRecipients() -> [Recipient] {
        if let data = data(forKey: "recipients"),
           let decoded = try? JSONDecoder().decode([Recipient].self, from: data) {
            return decoded
        }
        return []
    }
    
    func loadCategories() -> [Category] {
        if let data = data(forKey: "categories"),
           let decoded = try? JSONDecoder().decode([Category].self, from: data) {
            return decoded
        }
        return []
    }
}

// Main View
struct ContentView: View {
    @StateObject private var viewModel = GiftViewModel()
    
    var body: some View {
        TabView {
            GiftListView()
                .environmentObject(viewModel)
                .tabItem {
                    Image(systemName: "gift.fill")
                    Text("Gifts")
                }
            
            AddGiftView()
                .environmentObject(viewModel)
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Gift")
                }
            
            RecipientListView()
                .environmentObject(viewModel)
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Recipients")
                }
            
            CategoryListView()
                .environmentObject(viewModel)
                .tabItem {
                    Image(systemName: "tag.fill")
                    Text("Categories")
                }
        }
    }
}

// Gift List View
struct GiftListView: View {
    @EnvironmentObject var viewModel: GiftViewModel
    @State private var searchText = ""
    @State private var sortAscending = true
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    TextField("Search gifts...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    
                    Button(action: {
                        sortAscending.toggle()
                    }) {
                        Image(systemName: sortAscending ? "arrow.up" : "arrow.down")
                    }
                    .padding(.trailing)
                }
                
                List {
                    ForEach(filteredAndSortedGifts) { gift in
                        NavigationLink(destination: EditGiftView(gift: gift)) {
                            VStack(alignment: .leading) {
                                Text(gift.name)
                                    .font(.headline)
                                Text("Recipient: \(gift.recipient.name)")
                                    .font(.subheadline)
                                Text("Category: \(gift.category.name)")
                                    .font(.subheadline)
                                Text("Price: $\(gift.price, specifier: "%.2f")")
                                    .font(.subheadline)
                                Text("Store: \(gift.store)")
                                    .font(.subheadline)
                                Text("Status: \(gift.status)")
                                    .foregroundColor(gift.status == "Purchased" ? .green : .orange)
                            }
                        }
                    }
                    .onDelete(perform: viewModel.deleteGift)
                }
                .navigationTitle("Gift List")
                .toolbar {
                    EditButton()
                }
            }
        }
    }
    
    private var filteredAndSortedGifts: [Gift] {
        let filtered = viewModel.gifts.filter {
            searchText.isEmpty || $0.name.lowercased().contains(searchText.lowercased())
        }
        return filtered.sorted {
            sortAscending ? $0.name < $1.name : $0.name > $1.name
        }
    }
}

// Add Gift View
struct AddGiftView: View {
    @EnvironmentObject var viewModel: GiftViewModel
    @State private var name = ""
    @State private var description = ""
    @State private var status = "Pending"
    @State private var price = ""
    @State private var store = ""
    @State private var purchaseDate = Date()
    @State private var selectedRecipient: Recipient?
    @State private var selectedCategory: Category?
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Gift Name", text: $name)
                TextField("Description", text: $description)
                TextField("Price", text: $price)
                    .keyboardType(.decimalPad)
                TextField("Store", text: $store)
                
                DatePicker("Purchase Date", selection: $purchaseDate, displayedComponents: .date)
                
                Picker("Recipient", selection: $selectedRecipient) {
                    Text("Select Recipient").tag(nil as Recipient?)
                    ForEach(viewModel.recipients, id: \.self) { recipient in
                        Text(recipient.name).tag(recipient as Recipient?)
                    }
                }
                
                Picker("Category", selection: $selectedCategory) {
                    Text("Select Category").tag(nil as Category?)
                    ForEach(viewModel.categories, id: \.self) { category in
                        Text(category.name).tag(category as Category?)
                    }
                }
                
                Picker("Status", selection: $status) {
                    Text("Pending").tag("Pending")
                    Text("Purchased").tag("Purchased")
                }
                .pickerStyle(SegmentedPickerStyle())
                
                Button("Add Gift") {
                    addGift()
                }
                .disabled(name.isEmpty || price.isEmpty || selectedRecipient == nil || selectedCategory == nil)
            }
            .navigationTitle("Add Gift")
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Input Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    private func addGift() {
        guard !name.isEmpty else {
            alertMessage = "Gift name cannot be empty."
            showAlert = true
            return
        }
        guard let priceValue = Double(price) else {
            alertMessage = "Invalid price value."
            showAlert = true
            return
        }
        guard let recipient = selectedRecipient else {
            alertMessage = "Please select a recipient."
            showAlert = true
            return
        }
        guard let category = selectedCategory else {
            alertMessage = "Please select a category."
            showAlert = true
            return
        }
        
        let newGift = Gift(name: name, description: description, status: status, price: priceValue, store: store, purchaseDate: purchaseDate, recipient: recipient, category: category)
        viewModel.addGift(newGift)
        clearForm()
    }
    
    private func clearForm() {
        name = ""
        description = ""
        price = ""
        store = ""
        status = "Pending"
        selectedRecipient = nil
        selectedCategory = nil
        purchaseDate = Date()
    }
}

// Edit Gift View
// Edit Gift View
struct EditGiftView: View {
    @EnvironmentObject var viewModel: GiftViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var gift: Gift
    
    init(gift: Gift) {
        _gift = State(initialValue: gift)
    }
    
    var body: some View {
        Form {
            TextField("Gift Name", text: $gift.name)
            TextField("Description", text: $gift.description)
            TextField("Price", value: $gift.price, format: .number)
                .keyboardType(.decimalPad)
            TextField("Store", text: $gift.store)
            
            DatePicker("Purchase Date", selection: $gift.purchaseDate, displayedComponents: .date)
            
            Picker("Recipient", selection: $gift.recipient) {
                ForEach(viewModel.recipients, id: \.self) { recipient in
                    Text(recipient.name).tag(recipient)
                }
            }
            
            Picker("Category", selection: $gift.category) {
                ForEach(viewModel.categories, id: \.self) { category in
                    Text(category.name).tag(category)
                }
            }
            
            Picker("Status", selection: $gift.status) {
                Text("Pending").tag("Pending")
                Text("Purchased").tag("Purchased")
            }
            .pickerStyle(SegmentedPickerStyle())
            
            Button("Save Changes") {
                viewModel.updateGift(gift)
                presentationMode.wrappedValue.dismiss() // Dismiss the view after saving
            }
        }
        .navigationTitle("Edit Gift")
    }
}


// Recipient List View
struct RecipientListView: View {
    @EnvironmentObject var viewModel: GiftViewModel
    @State private var newRecipientName = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Add New Recipient")) {
                    TextField("Recipient Name", text: $newRecipientName)
                    Button("Add Recipient") {
                        if !newRecipientName.isEmpty {
                            let newRecipient = Recipient(name: newRecipientName)
                            viewModel.addRecipient(newRecipient)
                            newRecipientName = ""
                        }
                    }
                }
                
                Section(header: Text("Recipients")) {
                    ForEach(viewModel.recipients) { recipient in
                        Text(recipient.name)
                    }
                    .onDelete(perform: viewModel.deleteRecipient)
                }
            }
            .navigationTitle("Recipients")
            .toolbar {
                EditButton()
            }
        }
    }
}

// Category List View
struct CategoryListView: View {
    @EnvironmentObject var viewModel: GiftViewModel
    @State private var newCategoryName = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Add New Category")) {
                    TextField("Category Name", text: $newCategoryName)
                    Button("Add Category") {
                        if !newCategoryName.isEmpty {
                            let newCategory = Category(name: newCategoryName)
                            viewModel.addCategory(newCategory)
                            newCategoryName = ""
                        }
                    }
                }
                
                Section(header: Text("Categories")) {
                    ForEach(viewModel.categories) { category in
                        Text(category.name)
                    }
                    .onDelete(perform: viewModel.deleteCategory)
                }
            }
            .navigationTitle("Categories")
            .toolbar {
                EditButton()
            }
        }
    }
}

// App Entry Point
@main
struct GiftListOrganizerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
