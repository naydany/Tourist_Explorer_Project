import 'package:flutter/material.dart';

import 'core/app.dart';
import 'repositories/destination_repository.dart';

void main() {
  runApp(TouristExplorerApp(destinations: DestinationRepository()));
}
