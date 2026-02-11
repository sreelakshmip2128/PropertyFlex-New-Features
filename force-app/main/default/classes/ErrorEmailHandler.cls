global class ErrorEmailHandler implements Messaging.InboundEmailHandler {

    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();

        try {
            Exception_Log__c newLog = new Exception_Log__c();

            // Extract Flow name from email subject
            String flowName = extractFlowName(email.subject);

            newLog.Source__c = flowName != null ? flowName : 'Unknown Flow';
            newLog.Exception_Message__c = email.subject
;
            newLog.Occurred_On__c = System.now();
            newLog.Exception_Type__c = 'Flow Error';

            insert newLog;

            result.success = true;
        } catch (Exception e) {
            result.success = false;
            result.message = 'Failed to create error log: ' + e.getMessage();
        }

        return result;
    }

    // Utility method to extract text inside double quotes
    private static String extractFlowName(String subject) {
        if (subject == null) return null;

        // Regex to get first occurrence of text inside quotes
        Pattern p = Pattern.compile('"([^"]+)"');
        Matcher m = p.matcher(subject);

        if (m.find()) {
            return m.group(1);
        }
        return null;
    }
}