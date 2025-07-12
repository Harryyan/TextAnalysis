//
//  PDFViewWrapper.swift
//  TextAnalysis
//
//  Created by HarryYan on 11/07/2025.
//

import SwiftUI
import PDFKit

struct PDFViewWrapper: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        
        // Load the PDF document
        if let document = PDFDocument(url: url) {
            pdfView.document = document
        }
        
        // Configure the PDF view
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.usePageViewController(true, withViewOptions: nil)
        
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        // Update the document if URL changes
        if pdfView.document?.documentURL != url {
            if let document = PDFDocument(url: url) {
                pdfView.document = document
            }
        }
    }
}