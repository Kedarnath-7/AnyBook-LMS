//
//  IssuedBooksListView.swift
//  lib ms
//
//  Created by admin86 on 08/05/25.
//

import SwiftUI

struct IssuedBooksListView: View {
    @StateObject private var catalogViewModel = CatalogViewModel()
    @StateObject private var libraryViewModel = LibraryViewModel()
    @State private var searchText = ""
    
    private var issuedTransactions: [Transaction] {
        let transactions = libraryViewModel.transactions.filter { $0.status == "issued" }
        if searchText.isEmpty {
            return transactions
        } else {
            return transactions.filter { transaction in
                // Find the book title
                let bookTitle = catalogViewModel.books.first { $0.isbn == transaction.bookID }?.title ?? ""
                return bookTitle.lowercased().contains(searchText.lowercased()) ||
                       transaction.memberID.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                TextField("Search by book title or member ID", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                ScrollView {
                    VStack(spacing: 12) {
                        if issuedTransactions.isEmpty {
                            Text(searchText.isEmpty ? "No issued books found." : "No matching issued books found.")
                                .foregroundColor(.gray)
                                .padding()
                        } else {
                            ForEach(issuedTransactions) { transaction in
                                IssuedBookCard(
                                    transaction: transaction,
                                    catalogViewModel: catalogViewModel,
                                    libraryViewModel: libraryViewModel
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }
            }
            .navigationTitle("Issued Books")
            .onAppear {
                catalogViewModel.loadData()
                libraryViewModel.loadTransactions()
            }
        }
    }
}

struct IssuedBookCard: View {
    let transaction: Transaction
    @ObservedObject var catalogViewModel: CatalogViewModel
    @ObservedObject var libraryViewModel: LibraryViewModel

    private struct Constants {
        static let accentColor = Color(red: 0.2, green: 0.4, blue: 0.6)
    }

    private var book: Book? {
        catalogViewModel.books.first { $0.isbn == transaction.bookID }
    }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    var body: some View {
        HStack(spacing: 16) {
            // Load book cover image or use a fallback
            if let coverImageURL = book?.coverImageURL, let url = URL(string: coverImageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 60, height: 80)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 80)
                            .clipped()
                            .cornerRadius(8)
                    case .failure:
                        Image(systemName: "book.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 60)
                            .foregroundColor(Constants.accentColor)
                            .padding(.bottom, 4)
                    @unknown default:
                        Image(systemName: "book.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 60)
                            .foregroundColor(Constants.accentColor)
                            .padding(.bottom, 4)
                    }
                }
            } else {
                Image(systemName: "book.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 60)
                    .foregroundColor(Constants.accentColor)
                    .padding(.bottom, 4)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(book?.title ?? "Unknown Title")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.black)
                    .lineLimit(2)

                Text("Member ID: \(transaction.memberID)")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.gray)
                    .lineLimit(1)

                Text("Due: \(dateFormatter.string(from: transaction.dueDate.dateValue()))")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(.red)
            }

            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

struct IssuedBooksListView_Previews: PreviewProvider {
    static var previews: some View {
        IssuedBooksListView()
            .environmentObject(CatalogViewModel())
            .environmentObject(LibraryViewModel())
    }
}
