import Link from 'next/link';
import Navbar from '@/components/ui/Navbar';
import { Button } from '@/components/ui/Button';

export default function AboutPage() {
  return (
    <>
      <Navbar />
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="text-center mb-12">
          <h1 className="text-4xl font-bold text-gray-900 dark:text-white">About DAANSETU</h1>
          <p className="mt-4 text-xl text-gray-600 dark:text-gray-300 max-w-3xl mx-auto">
            Connecting donors with NGOs to maximize social impact through efficient donation management
          </p>
        </div>
        
        <div className="grid grid-cols-1 md:grid-cols-2 gap-12 mb-16">
          <div>
            <h2 className="text-2xl font-bold text-gray-900 dark:text-white mb-4">Our Mission</h2>
            <p className="text-gray-600 dark:text-gray-300 mb-4">
              DAANSETU (meaning "Bridge of Giving") aims to bridge the gap between donors and NGOs by providing a 
              streamlined platform for donation management. We believe that by making the donation process more 
              efficient and transparent, we can maximize the impact of every contribution.
            </p>
            <p className="text-gray-600 dark:text-gray-300">
              Our platform enables donors to easily donate items they no longer need, and helps NGOs find and claim 
              donations that match their requirements. By facilitating these connections, we reduce waste and 
              ensure resources reach those who need them most.
            </p>
          </div>
          <div className="bg-gray-100 dark:bg-zinc-800/50 rounded-lg overflow-hidden shadow-sm">
            <div className="p-6">
              <h3 className="text-xl font-bold text-gray-900 dark:text-white mb-3">Key Features</h3>
              <ul className="space-y-3">
                <li className="flex">
                  <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6 text-primary flex-shrink-0 mr-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                  </svg>
                  <span className="text-gray-600 dark:text-gray-300">Easy donation creation and management</span>
                </li>
                <li className="flex">
                  <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6 text-primary flex-shrink-0 mr-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                  </svg>
                  <span className="text-gray-600 dark:text-gray-300">Location-based matching of donations to nearby NGOs</span>
                </li>
                <li className="flex">
                  <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6 text-primary flex-shrink-0 mr-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                  </svg>
                  <span className="text-gray-600 dark:text-gray-300">NGO verification system for trust and reliability</span>
                </li>
                <li className="flex">
                  <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6 text-primary flex-shrink-0 mr-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                  </svg>
                  <span className="text-gray-600 dark:text-gray-300">Request system for NGOs to specify their needs</span>
                </li>
                <li className="flex">
                  <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6 text-primary flex-shrink-0 mr-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                  </svg>
                  <span className="text-gray-600 dark:text-gray-300">Real-time tracking of donation status</span>
                </li>
              </ul>
            </div>
          </div>
        </div>
        
        <div className="mb-16">
          <h2 className="text-2xl font-bold text-gray-900 dark:text-white mb-6 text-center">How It Works</h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            <div className="bg-white dark:bg-zinc-800 rounded-lg shadow-sm p-6 text-center">
              <div className="inline-flex items-center justify-center w-12 h-12 rounded-full bg-primary/10 text-primary mb-4">
                <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6v6m0 0v6m0-6h6m-6 0H6" />
                </svg>
              </div>
              <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-2">For Donors</h3>
              <p className="text-gray-600 dark:text-gray-300 mb-4">
                Create an account, add details about items you want to donate, and our platform will connect you with 
                nearby NGOs that need your items.
              </p>
              <Link href="/auth/register">
                <Button variant="outline" size="sm">Join as Donor</Button>
              </Link>
            </div>
            
            <div className="bg-white dark:bg-zinc-800 rounded-lg shadow-sm p-6 text-center">
              <div className="inline-flex items-center justify-center w-12 h-12 rounded-full bg-primary/10 text-primary mb-4">
                <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 12a9 9 0 01-9 9m9-9a9 9 0 00-9-9m9 9H3m9 9a9 9 0 01-9-9m9 9c1.657 0 3-4.03 3-9s-1.343-9-3-9m0 18c-1.657 0-3-4.03-3-9s1.343-9 3-9" />
                </svg>
              </div>
              <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-2">For NGOs</h3>
              <p className="text-gray-600 dark:text-gray-300 mb-4">
                Register your organization, get verified, and access a dashboard where you can claim donations that match 
                your needs or create specific requests.
              </p>
              <Link href="/auth/register">
                <Button variant="outline" size="sm">Register NGO</Button>
              </Link>
            </div>
            
            <div className="bg-white dark:bg-zinc-800 rounded-lg shadow-sm p-6 text-center">
              <div className="inline-flex items-center justify-center w-12 h-12 rounded-full bg-primary/10 text-primary mb-4">
                <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
                </svg>
              </div>
              <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-2">Security & Trust</h3>
              <p className="text-gray-600 dark:text-gray-300 mb-4">
                We verify all NGOs on our platform to ensure legitimacy. Donors can track their donations and see 
                the impact they make through our transparent system.
              </p>
              <Link href="/verification">
                <Button variant="outline" size="sm">Learn About Verification</Button>
              </Link>
            </div>
          </div>
        </div>
        
        <div className="mb-16">
          <h2 className="text-2xl font-bold text-gray-900 dark:text-white mb-6 text-center">Our Impact</h2>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
            <div className="bg-white dark:bg-zinc-800 rounded-lg shadow-sm p-6 text-center">
              <div className="text-3xl font-bold text-primary mb-2">1,000+</div>
              <div className="text-gray-600 dark:text-gray-300">Donations Facilitated</div>
            </div>
            <div className="bg-white dark:bg-zinc-800 rounded-lg shadow-sm p-6 text-center">
              <div className="text-3xl font-bold text-primary mb-2">50+</div>
              <div className="text-gray-600 dark:text-gray-300">Verified NGOs</div>
            </div>
            <div className="bg-white dark:bg-zinc-800 rounded-lg shadow-sm p-6 text-center">
              <div className="text-3xl font-bold text-primary mb-2">20+</div>
              <div className="text-gray-600 dark:text-gray-300">Cities Covered</div>
            </div>
            <div className="bg-white dark:bg-zinc-800 rounded-lg shadow-sm p-6 text-center">
              <div className="text-3xl font-bold text-primary mb-2">5,000+</div>
              <div className="text-gray-600 dark:text-gray-300">Lives Impacted</div>
            </div>
          </div>
        </div>
        
        <div className="bg-primary/10 rounded-lg shadow-sm p-8 flex flex-col md:flex-row items-center justify-between">
          <div className="mb-6 md:mb-0 md:mr-8">
            <h2 className="text-2xl font-bold text-gray-900 dark:text-white mb-2">Ready to Make a Difference?</h2>
            <p className="text-gray-600 dark:text-gray-300">
              Join DAANSETU today and be part of our mission to connect donations with those who need them most.
            </p>
          </div>
          <div className="flex flex-col sm:flex-row gap-4">
            <Link href="/auth/register">
              <Button>Join Now</Button>
            </Link>
            <Link href="/contact">
              <Button variant="outline">Contact Us</Button>
            </Link>
          </div>
        </div>
        
        <div className="mt-16 text-center">
          <h2 className="text-2xl font-bold text-gray-900 dark:text-white mb-4">Our Team</h2>
          <p className="text-gray-600 dark:text-gray-300 max-w-3xl mx-auto mb-8">
            DAANSETU was founded by a team of passionate individuals committed to creating positive social impact 
            through technology and innovation.
          </p>
          
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-8 max-w-4xl mx-auto">
            <div className="bg-white dark:bg-zinc-800 rounded-lg shadow-sm p-6">
              <div className="w-24 h-24 rounded-full bg-gray-200 dark:bg-gray-700 mx-auto mb-4"></div>
              <h3 className="text-lg font-semibold text-gray-900 dark:text-white">Aarav Sharma</h3>
              <p className="text-primary text-sm mb-2">Founder & CEO</p>
              <p className="text-gray-600 dark:text-gray-300 text-sm">
                Passionate about social entrepreneurship and technology for good
              </p>
            </div>
            
            <div className="bg-white dark:bg-zinc-800 rounded-lg shadow-sm p-6">
              <div className="w-24 h-24 rounded-full bg-gray-200 dark:bg-gray-700 mx-auto mb-4"></div>
              <h3 className="text-lg font-semibold text-gray-900 dark:text-white">Priya Patel</h3>
              <p className="text-primary text-sm mb-2">Chief Operations Officer</p>
              <p className="text-gray-600 dark:text-gray-300 text-sm">
                Experience in NGO management and community development
              </p>
            </div>
            
            <div className="bg-white dark:bg-zinc-800 rounded-lg shadow-sm p-6">
              <div className="w-24 h-24 rounded-full bg-gray-200 dark:bg-gray-700 mx-auto mb-4"></div>
              <h3 className="text-lg font-semibold text-gray-900 dark:text-white">Arjun Mehta</h3>
              <p className="text-primary text-sm mb-2">Chief Technology Officer</p>
              <p className="text-gray-600 dark:text-gray-300 text-sm">
                Full-stack developer with a focus on creating accessible technology solutions
              </p>
            </div>
          </div>
        </div>
      </div>
    </>
  );
} 