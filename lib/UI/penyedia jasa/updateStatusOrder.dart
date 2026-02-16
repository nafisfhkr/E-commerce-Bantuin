import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 

class UpdateStatusPerbaikan extends StatefulWidget {
  const UpdateStatusPerbaikan({Key? key}) : super(key: key);

  @override
  State<UpdateStatusPerbaikan> createState() => _UpdateStatusPerbaikanState();
}

class _UpdateStatusPerbaikanState extends State<UpdateStatusPerbaikan> {
  final List<RepairStatusItem> statusItems = [
    RepairStatusItem(
      title: "Pesanan diterima",
      description: "Pesanan telah diterima, teknisi kami sedang menuju lokasi",
      isCompleted: true,
      date: DateTime(2023, 4, 26, 9, 30),
      isActive: false,
    ),
    RepairStatusItem(
      title: "Pesanan diterima",
      description: "Kami akan segera datang ke lokasi sesuai dengan jadwal",
      isCompleted: true,
      date: DateTime(2023, 4, 26, 10, 0),
      isActive: true,
    ),
    RepairStatusItem(
      title: "Sedang diperbaiki",
      description: "Teknisi sedang bekerja perbaikan",
      isCompleted: false,
      date: DateTime(2023, 4, 26, 11, 0),
      isActive: false,
      hasImages: true,
    ),
    RepairStatusItem(
      title: "Pesanan diterima",
      description: "Kami akan segera menyelesaikan sesuai dengan jadwal",
      isCompleted: false,
      date: DateTime(2023, 4, 26, 12, 0),
      isActive: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Update Status Perbaikan',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCustomerInfoCard(),
              
              const SizedBox(height: 20),
              
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status Perbaikan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    _buildStatusTimeline(),
                    
                    const SizedBox(height: 16),
 
                    InkWell(
                      onTap: () {
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF3FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF192F6A).withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'Tambah Status Pesanan',
                            style: TextStyle(
                              color: Color(0xFF192F6A),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF192F6A),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Ahmad Bintang',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Pelanggan #HZN7C13',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildStatusTimeline() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: statusItems.length,
      itemBuilder: (context, index) {
        final item = statusItems[index];
        final bool isLast = index == statusItems.length - 1;
        
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  _buildStatusIndicator(item.isCompleted),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: const Color(0xFFE0E0E0),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  margin: EdgeInsets.only(bottom: isLast ? 0 : 20),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: item.isActive 
                        ? const Color(0xFFEEF3FF) 
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      if (item.hasImages) const SizedBox(height: 12),
                      if (item.hasImages)
                        Row(
                          children: [
                            _buildImagePlaceholder(),
                            const SizedBox(width: 8),
                            _buildImagePlaceholder(),
                          ],
                        ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDate(item.date),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                          if (item.isActive)
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16, 
                                  vertical: 6,
                                ),
                                minimumSize: Size(0, 30),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              child: Text(
                                'Selesai',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusIndicator(bool isCompleted) {
    return Container(
      width: 24.0,
      height: 24.0,
      decoration: BoxDecoration(
        color: isCompleted ? const Color(0xFF192F6A) : Colors.white,
        shape: BoxShape.circle,
        border: isCompleted 
            ? null 
            : Border.all(color: Colors.grey, width: 1.5),
      ),
      child: Center(
        child: Icon(
          Icons.check,
          size: 16.0,
          color: isCompleted ? Colors.white : Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF192F6A),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '• ${DateFormat('d MMM yyyy, HH:mm').format(date)}';
  }
}

class RepairStatusItem {
  final String title;
  final String description;
  final bool isCompleted;
  final DateTime date;
  final bool isActive;
  final bool hasImages;

  RepairStatusItem({
    required this.title,
    required this.description,
    required this.isCompleted,
    required this.date,
    required this.isActive,
    this.hasImages = false,
  });
}