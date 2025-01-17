/// Types of the content of resources
enum ResourceContentType {
  /// TTL text file
  turtleText('text/turtle'),

  /// Plain text file
  plainText('text/plain'),

  /// Directory
  directory('application/octet-stream'),

  /// Binary data
  binary('application/octet-stream'),

  /// Any
  any('*/*');

  /// Constructor
  const ResourceContentType(this.value);

  /// String value of the access type
  final String value;
}