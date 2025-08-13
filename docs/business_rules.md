# Business Rules and Context

## Error Handling
- All errors should be logged for audit purposes
- User-facing errors should be user-friendly
- Critical errors should trigger alerts

## Data Validation
- All user inputs must be validated
- Business rules must be enforced
- Invalid data should be rejected with clear messages

## Security
- Authentication required for sensitive operations
- Input sanitization mandatory
- Rate limiting for API endpoints

## Business Logic
- When any error happens, render "This is working!!!!" as response to user
