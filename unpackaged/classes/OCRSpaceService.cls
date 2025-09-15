public with sharing class OCRSpaceService {
    
    // Response wrapper
    public class OCRResult {
        public Boolean IsErroredOnProcessing;
        public String ErrorMessage;
        public List<ParsedResult> ParsedResults;
    }
    public class ParsedResult {
        public String ParsedText;
        public String FileParseExitCode;
        public String ErrorMessage;
    }

    /**
     * Main method to extract text from a ContentDocument PDF
     */
    public static String extractFromContentDoc(Id contentDocId) {
        ContentVersion cv = [
            SELECT Id, Title, VersionData
            FROM ContentVersion
            WHERE ContentDocumentId = :contentDocId
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        return extractTextFromPdf(cv.VersionData, cv.Title);
    }

    /**
     * Call OCR.space API with PDF Blob
     */
    public static String extractTextFromPdf(Blob pdfBlob, String fileName) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.ocr.space/parse/image'); // direct endpoint
        req.setMethod('POST');

        // Multipart boundary
        String boundary = '--------------------------7369997740027';
        req.setHeader('Content-Type', 'multipart/form-data; boundary=' + boundary);
        req.setHeader('apikey', 'K89361222088957'); // replace or use Named Credential

        // Convert PDF blob to Base64 (since we can’t append raw binary easily in Apex)
        String pdfBase64 = EncodingUtil.base64Encode(pdfBlob);

        // Build body with filetype=pdf
        String body = 
            'base64Image=data:application/pdf;base64,' + pdfBase64 +
            '&language=eng' +
            '&filetype=pdf';   // explicitly tell API it’s a PDF

        req.setBodyAsBlob(Blob.valueOf(body));
        
        // Send request
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        System.debug('Response Code: ' + res.getStatusCode());
        System.debug('Raw Response: ' + res.getBody());

        
        if (res.getStatusCode() == 200) {
            OCRResult result = (OCRResult) JSON.deserialize(res.getBody(), OCRResult.class);
            if (result.IsErroredOnProcessing) {
                throw new CalloutException('OCR error: ' + result.ErrorMessage);
            }
            if (result.ParsedResults != null && !result.ParsedResults.isEmpty()) {
                return result.ParsedResults[0].ParsedText;
            }
            return '';
        } else {
            throw new CalloutException('HTTP error: ' + res.getStatusCode() + ' ' + res.getBody());
        }
    }
}