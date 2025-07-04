import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_charts/charts.dart';

class WatchlistScreen extends StatefulWidget {
  @override
  _WatchlistScreenState createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  Map<String, double> prices = {};
  List<String> symbols = ['GAIL.NS', 'RELIANCE.NS', 'TCS.NS'];
  List<PricePoint> chartData = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchPrices();
    _timer = Timer.periodic(Duration(seconds: 5), (_) => _fetchPrices());
  }

  Future<void> _fetchPrices() async {
    for (String symbol in symbols) {
      final price = await fetchPrice(symbol);
      if (price != null) {
        setState(() {
          prices[symbol] = price;
          chartData.add(PricePoint(DateTime.now(), price));
          if (chartData.length > 20) chartData.removeAt(0);
        });
      }
    }
  }

  Future<double?> fetchPrice(String symbol) async {
    final url = Uri.parse('https://query1.finance.yahoo.com/v8/finance/chart/$symbol');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['chart']['result'][0]['meta']['regularMarketPrice']?.toDouble();
    }
    return null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            children: symbols.map((symbol) {
              final price = prices[symbol] ?? 0;
              return ListTile(
                title: Text(symbol, style: TextStyle(color: Colors.white)),
                trailing: Text('₹${price.toStringAsFixed(2)}', style: TextStyle(color: Colors.greenAccent)),
              );
            }).toList(),
          ),
        ),
        SizedBox(
          height: 200,
          child: SfCartesianChart(
            primaryXAxis: DateTimeAxis(),
            series: <ChartSeries>[
              LineSeries<PricePoint, DateTime>(
                dataSource: chartData,
                xValueMapper: (PricePoint p, _) => p.time,
                yValueMapper: (PricePoint p, _) => p.price,
              )
            ],
          ),
        ),
      ],
    );
  }
}

class PricePoint {
  final DateTime time;
  final double price;
  PricePoint(this.time, this.price);
}
